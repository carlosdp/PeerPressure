import { createSupabaseClient } from "../_shared/supabase.ts";
import {
  BuilderConversationData,
  generateInitialConversationMessage,
} from "./initialConversation.ts";
import { generateEditorConversationMessage } from "./editorConversation.ts";

Deno.serve(async (req) => {
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
      progress: 0,
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
      progress: 0,
    });
  }

  const conversation =
    conversationData.conversations[conversationData.conversations.length - 1];
  conversation.messages.push({ role: "user", content: message });

  const newConversation = conversationData.conversations.length > 1
    ? await generateEditorConversationMessage(profile, conversation)
    : await generateInitialConversationMessage(
      profile,
      conversation,
    );

  conversationData.conversations[conversationData.conversations.length - 1] =
    newConversation;

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
      status: newConversation.state,
      message: newConversation.messages[newConversation.messages.length - 1],
      progress: newConversation.progress,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
