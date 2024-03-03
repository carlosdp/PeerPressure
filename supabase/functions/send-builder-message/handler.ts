import { createSupabaseClient } from "../_shared/supabase.ts";
import { rawMessage } from "../_shared/utils.ts";
import { createJob } from "../worker/job.ts";

export type BuilderConversationData = {
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

    await createJob("buildProfile", { profileId: profile.id });
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
