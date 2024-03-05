import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import { rawMessage } from "../../_shared/utils.ts";
import logger from "../../logger.ts";
import type { Photo } from "../../_shared/supabaseJsonTypes.d.ts";

const CONSTRUCTION_PROMPT =
  `You are an expert dating profile creator that helps clients construct a fun, whimsical dating profile that helps them attract the right person for them. Taking into account the guidelines below, and the current profile, edit the profile to make the changes described by the user.

  Guidelines:
  - Profiles are expressed as a list of "blocks" of different types, organized in a vertical profile on mobile phones
  - The first block should always be a profile photo. Profile photos should always be the best photo that makes the client look attractive and approachable. Ideally, profile photos show only the client, or they take up most of the frame, so suitors know which person they are in the photo easily.
  - Keep in mind that basic profile information (height, education, etc.) will always be shown by the app after the first block, and the rest of the blocks will be presented after.
  - Match "gas" blocks up with relevant photos provided when possible
  - There should be about 5-7 blocks in the profile.
  - When editing profiles, make sure the new profile at least as many images as the original profile.

  Basic Profile Information: {profile}
  Photos: {photos}
  Current Profile: {current_profile}`;

export type ChangeProfileJob = {
  profileId: string;
  changes: string;
};

async function job(job: Job<ChangeProfileJob>) {
  logger.info(`Changing profile ${job.data.profileId}: ${job.data.changes}`);

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

  const photos = profile.available_photos as Photo[];

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
      ).replace("{current_profile}", JSON.stringify(profile.blocks)).replace(
        "{photos}",
        JSON.stringify(photos),
      ),
    },
    {
      role: "user",
      content: job.data.changes,
    },
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
                        required: ["image"],
                        properties: {
                          image: {
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
