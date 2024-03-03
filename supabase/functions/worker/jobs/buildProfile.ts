import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import type { BuilderConversationData } from "../../send-builder-message/handler.ts";
import { rawMessage } from "../../_shared/utils.ts";
import logger from "../../logger.ts";

const CONSTRUCTION_PROMPT =
  `You are an expert dating profile creator that helps clients construct a fun, whimsical dating profile that helps them attract the right person for them. Taking into account the guidelines below, construct a dating profile for the given client.

  Guidelines:
  - Profiles are expressed as a list of "blocks" of different types, organized in a vertical profile on mobile phones
  - The first block should always be a profile photo. Profile photos should always be the best photo that makes the client look attractive and approachable. Ideally, profile photos show only the client, or they take up most of the frame, so suitors know which person they are in the photo easily.
  - Keep in mind that basic profile information (height, education, etc.) will always be shown by the app after the first block, and the rest of the blocks will be presented after.
  - Match "gas" blocks up with relevant photos provided when possible
  - There should be about 5-7 blocks in the profile.

  Profile Information: {profile}
  Photos: {photos}
  Conversaton:`;

export type BuildProfileJob = {
  profileId: string;
};

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, _) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.readAsDataURL(blob);
  });
}

async function job(job: Job<BuildProfileJob>) {
  logger.info(`Building profile ${job.data.profileId}`);

  const { data: profile, error: profileError } = await supabase.from(
    "profiles",
  )
    .select().eq("id", job.data.profileId).single();
  if (profileError) {
    console.error("Error getting profile:", profileError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const conversationData = profile
    .builder_conversation_data as BuilderConversationData;
  const conversation = conversationData.conversations?.findLast((c) =>
    c.state === "finished"
  );

  if (!conversation) {
    console.error("No finished conversation");
    return;
  }

  const photoKeys = profile.available_photo_keys as string[];

  const photos = await Promise.all(photoKeys.map(async (key) => {
    const { data: photo, error: photoError } = await supabase.storage.from(
      "photos",
    ).download(key);
    if (photoError) {
      console.error("Error getting photo:", photoError.message);
      throw photoError;
    }

    const dataUrl = await blobToBase64(photo);

    return { key, dataUrl };
  }));

  // Pre process user photos, since GPT-4 Vision preview does not yet support tool calls
  const photoMessage = await rawMessage("gpt-4-vision-preview", [
    {
      role: "system",
      content:
        `The following are photos provided by a user to a dating app. Given the images provided, write a short description of the image and what the user is doing in the photo. Make sure to describe if the user is with other people in the photo, and how prominent they are in the photo, so that we can determine if it is a good representative image for people trying to figure out what the user looks like.
        
        Respond in the following JSON array format:
        [{ key: "<photo key here>", description: "<description here>" }, ...]`,
    },
    {
      role: "user",
      content: photos.flatMap((photo) => [
        {
          type: "text",
          text: `Key: ${photo.key}`,
        },
        {
          type: "image_url",
          image_url: { url: photo.dataUrl, detail: "low" },
        },
      ]),
    },
    {
      role: "system",
      content: "Respond in pure JSON only",
    },
  ], {
    maxTokens: 1000,
    temperature: 0,
  });

  if (!photoMessage.content || typeof photoMessage.content !== "string") {
    console.error("No photo message content");
    return;
  }
  console.log("Photo message:", photoMessage.content);

  const constructMessage = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content: CONSTRUCTION_PROMPT.replace(
        "{profile}",
        JSON.stringify({
          name: profile.first_name,
          gender: profile.gender,
          location: profile.display_location,
          age: new Date(profile.birth_date).getFullYear() -
            new Date().getFullYear(),
        }),
      ).replace("{photos}", photoMessage.content),
    },
    ...conversation.messages,
  ], {
    temperature: 0.5,
    maxTokens: 2000,
    toolChoice: { type: "function", function: { name: "construct" } },
    tools: [
      {
        type: "function",
        function: {
          name: "construct",
          description: "Construct the final profile blocks",
          parameters: {
            type: "object",
            properties: {
              blocks: {
                oneOf: [
                  {
                    type: "object",
                    description: "A photo from the user's collection",
                    required: ["photo"],
                    properties: {
                      photo: {
                        type: "object",
                        required: ["key"],
                        properties: {
                          key: {
                            type: "string",
                            description: "The photo key",
                          },
                        },
                      },
                    },
                  },
                  {
                    type: "object",
                    description:
                      "A paragraph of text telling potential suitors something exciting about the client's personality, character, or life. Should be in a fun, whimsical, approachable tone and use jokes / puns / wordplay when possible. Use of emojis is encouraged. Should be written in the third person.",
                    required: ["gas"],
                    properties: {
                      gas: {
                        type: "object",
                        required: ["text"],
                        properties: {
                          text: {
                            type: "string",
                            description:
                              "The text, feel free to use emojis and markdown for bolding/italics etc.",
                          },
                        },
                      },
                    },
                  },
                ],
              },
            },
          },
        },
      },
    ],
  });

  if (constructMessage.content || !constructMessage.tool_calls) {
    console.error("No construct message tool call");
    return;
  }

  console.log(constructMessage.tool_calls[0].function.arguments);

  const args = JSON.parse(constructMessage.tool_calls[0].function.arguments);

  const { error: updateError } = await supabase.from("profiles").update({
    blocks: args.blocks,
  }).eq("id", profile.id);
  if (updateError) {
    console.error("Error updating profile:", updateError.message);
    return;
  }
}

export default job;
