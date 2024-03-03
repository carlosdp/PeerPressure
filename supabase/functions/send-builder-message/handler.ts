import { createSupabaseClient, supabase } from "../_shared/supabase.ts";
import { rawMessage } from "../_shared/utils.ts";

type BuilderConversationData = {
  conversations?: {
    messages: { role: string; content: string }[];
    state: "active" | "finished";
  }[];
};

const PROMPT =
  `You are an expert dating coach that is helping a client create their dating profile. Use the profile information below to ask the client several short questions to get to know them better and their interests, so that you can create prompts for a dating profile for them.

  Rules:
  - Only ask for clarifying questions on things that would be potentially interesting to a potential date. For example, details about how someone's job works is not interesting.
  - When you have a good answer in an area, move on to another area in a natural way. Each area should have a maximum of two questions.
  - You only have 10 responses maximum to gather information for the profile, so don't linger on a topic too long and cover as much ground as possible.
  - Ask questions about the area specified.
  
  Profile Information: {profile}

  Areas to ask about (in no particular order):
  - Hobbies / Free time
  - Career
  - What is most important to them in their life? Career? Family? Friends? Hobbies?
  - What are they looking for in a partner?
  - What are they passionate about?
  - Do they travel?`;

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

const db = await Deno.openKv();

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, _) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.readAsDataURL(blob);
  });
}

export async function jobHandler({ profileId }: { profileId: string }) {
  const { data: profile, error: profileError } = await supabase.from("profiles")
    .select().eq("id", profileId).single();
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
          image_url: { url: photo.dataUrl },
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
                          key: { type: "string", description: "The photo key" },
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

export const handler: Deno.ServeHandler = async (req) => {
  const { message } = await req.json();

  const supabase = createSupabaseClient(req.headers.get("Authorization")!);

  const { error } = await supabase.auth.getUser();
  if (error) {
    console.log("Error getting user:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: profile, error: profileError } = await supabase.rpc(
    "get_profile",
  );
  if (profileError) {
    console.error("Error getting profile:", profileError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const conversationData = profile
    .builder_conversation_data as BuilderConversationData;

  if (!conversationData.conversations) {
    // initial conversation
    conversationData.conversations = [{
      messages: [
        { role: "assistant", content: "Ready to get started?" },
      ],
      state: "active",
    }];
  } else if (
    !conversationData.conversations.find((c) => c.state === "active")
  ) {
    // starting new conversation
    conversationData.conversations.push({
      messages: [
        { role: "assistant", content: "Ready to get started?" },
      ],
      state: "active",
    });
  }

  const conversation =
    conversationData.conversations[conversationData.conversations.length - 1];
  conversation.messages.push({ role: "user", content: message });

  const directionMessage = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content: PROMPT.replace(
        "{profile}",
        JSON.stringify({
          name: profile.first_name,
          location: profile.display_location,
          age: new Date(profile.birth_date).getFullYear() -
            new Date().getFullYear(),
        }),
      ),
    },
    ...conversation.messages,
    {
      role: "system",
      content: `${
        conversation.messages.filter((m) => m.role === "user").length
      } / 10 responses used. Based on the conversation, decide the next area to ask about. Only output the next area to ask about.`,
    },
  ], {
    temperature: 0.5,
    maxTokens: 500,
  });

  if (
    !directionMessage.content || typeof directionMessage.content !== "string"
  ) {
    console.error("No direction message content");
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  console.log("Direction message:", directionMessage.content);

  const newMessage = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content: PROMPT.replace(
        "{profile}",
        JSON.stringify({
          name: profile.first_name,
          gender: profile.gender,
          location: profile.display_location,
          age: new Date(profile.birth_date).getFullYear() -
            new Date().getFullYear(),
        }),
      ),
    },
    ...conversation.messages,
    {
      role: "system",
      content: `Area to ask about: ${directionMessage.content}`,
    },
  ], {
    temperature: 0.5,
    maxTokens: 500,
    tools: [
      {
        type: "function",
        function: {
          name: "finish",
          description: "Finish the conversation",
          parameters: {
            type: "object",
            properties: {},
          },
        },
      },
    ],
  });

  const newConversationMessage = {
    role: "assistant",
    content: "",
  };

  console.log("New message:", newMessage);

  if (typeof newMessage.content === "string") {
    newConversationMessage.content = newMessage.content;
  } else if (
    !newMessage.content && newMessage.tool_calls[0]?.function.name === "finish"
  ) {
    conversation.state = "finished";
    newConversationMessage.content = "Thank you! Working on your profile...";

    await db.enqueue({ queue: "send-builder-message", profileId: profile.id });
  } else {
    console.error("No message content");
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  conversation.messages.push(newConversationMessage);
  conversationData.conversations[conversationData.conversations.length - 1] =
    conversation;

  const { error: updateError } = await supabase.from("profiles").update({
    builder_conversation_data: conversationData,
  }).eq("id", profile.id);
  if (updateError) {
    console.error("Error updating profile:", updateError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({
      status: conversation.state,
      message: newConversationMessage,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
};
