import { rawMessage } from "../_shared/utils.ts";
import { createJob } from "../worker/job.ts";
import type { Database } from "../_shared/supabaseTypes.d.ts";
import type { BuilderConversationData } from "./handler.ts";
import type { Block, Photo } from "../_shared/supabaseJsonTypes.d.ts";

const PROMPT =
  `You are an expert dating coach that is helping a client edit their dating profile. If they ask to expand on their profile more, use the profile information below to ask the client several short questions to get to know them better and their interests, so that you can refine and modify their profile for them. If they want a specific modification, you can just make it for them.

  Rules for asking questions:
  - Only ask for clarifying questions on things that would be potentially interesting to a potential date. For example, details about how someone's job works is not interesting.
  - When you have a good answer in an area, move on to another area in a natural way. Each area should have a maximum of two questions.
  - You only have 10 responses maximum to gather information for the profile, so don't linger on a topic too long and cover as much ground as possible.
  - Ask questions about the area specified.

  Areas to ask about (in no particular order):
  - What their love languages are
  - What their ideal date looks like
  - A time they had a really bad date, and why it was bad
  - A time they had a really good date, and why it was good
  - Their relationship history, have they been in long term relationships before?
  - Are they looking for something long-term or casual?
  - Describe the best vacation they've ever been on
  - What's an embarrasing thing about them
  - Ask them for a secret
  
  Basic Profile Information: {profile}
  Available Photos: {photos}
  Current Profile: {current_profile}`;

export async function generateEditorConversationMessage(
  profile: Database["public"]["Tables"]["profiles"]["Row"],
  conversation: NonNullable<BuilderConversationData["conversations"]>[number],
) {
  const blocks = profile.blocks as Block[];
  const availablePhotos = profile.available_photos as Photo[];
  const hydratedBlocks = blocks.map((block) => {
    if ("photo" in block) {
      return {
        photo: {
          ...block.photo,
          description: availablePhotos.find((p) => p.key === block.photo.key)
            ?.description,
        },
      };
    }

    return block;
  });

  const finalPrompt = PROMPT.replace(
    "{profile}",
    JSON.stringify({
      name: profile.first_name,
      location: profile.display_location,
      age: new Date(profile.birth_date).getFullYear() -
        new Date().getFullYear(),
    }),
  ).replace("{current_profile}", JSON.stringify(hydratedBlocks)).replace(
    "{photos}",
    JSON.stringify(availablePhotos),
  );

  const directionMessage = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content: finalPrompt,
    },
    ...conversation.messages,
    {
      role: "system",
      content: `${
        conversation.messages.filter((m) => m.role === "user").length
      } / 10 responses used. Based on the conversation, decide the next area to ask about. Only output the next area to ask about, unless the user is asking for a specific change, in which case say what change to make.`,
    },
  ], {
    temperature: 0.5,
    maxTokens: 500,
  });

  if (
    !directionMessage.content || typeof directionMessage.content !== "string"
  ) {
    throw new Error("No direction message content");
  }

  console.log("Direction message:", directionMessage.content);

  const newMessage = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content: finalPrompt,
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
          name: "change_profile",
          description: "Describe the changes to make to the profile in detail",
          parameters: {
            type: "object",
            properties: {
              changes: {
                type: "string",
                description:
                  "A detailed description of the changes to make to the profile. Refer to any images by their key or their description",
              },
            },
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
    !newMessage.content &&
    newMessage.tool_calls[0]?.function.name === "change_profile"
  ) {
    const args = JSON.parse(newMessage.tool_calls[0].function.arguments);
    conversation.state = "finished";
    newConversationMessage.content =
      "Thank you! Working on a new profile for you...";

    await createJob("changeProfile", {
      profileId: profile.id,
      changes: args.changes,
    });
  } else {
    throw new Error("No message content");
  }

  conversation.messages.push(newConversationMessage);

  return conversation;
}
