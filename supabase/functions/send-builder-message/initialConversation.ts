import { rawMessage } from "../_shared/utils.ts";
import { createJob } from "../worker/job.ts";
import type { Database } from "../_shared/supabaseTypes.d.ts";
import type { BuilderConversationData } from "./handler.ts";

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

export async function generateInitialConversationMessage(
  profile: Database["public"]["Tables"]["profiles"]["Row"],
  conversation: NonNullable<BuilderConversationData["conversations"]>[number],
) {
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
    throw new Error("No direction message content");
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

    await createJob("buildProfile", { profileId: profile.id });
  } else {
    throw new Error("No message content");
  }

  conversation.messages.push(newConversationMessage);

  return conversation;
}
