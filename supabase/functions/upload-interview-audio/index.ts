import { createSupabaseClient } from "../_shared/supabase.ts";
import { transcribe } from "../_shared/utils.ts";
import { generateEditorConversationMessage } from "../send-builder-message/editorConversation.ts";
import {
  BuilderConversationData,
  generateInitialConversationMessage,
} from "../send-builder-message/initialConversation.ts";

Deno.serve(async (req) => {
  const { text, audio, interruption } = await req.json();

  const supabase = createSupabaseClient(req.headers.get("Authorization")!);

  let transcription: string;

  if (audio) {
    const audioBlob = await fetch(audio).then((res) => res.blob());
    transcription = await transcribe(audioBlob);

    if (transcription.length === 0) {
      return new Response(
        JSON.stringify({ error: "Transcription empty" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
  } else if (text) {
    transcription = text;
  } else {
    return new Response(
      JSON.stringify({ error: "No text or audio provided" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

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
  conversation.messages.push({
    role: "user",
    content: transcription,
    // it's only an interruption if the last message was not from the user,
    // from the LLM's perspective
    interruption: interruption &&
      conversation.messages[conversation.messages.length - 1].role !==
        "user",
  });

  const streamRes = await generateInitialConversationMessage(
    profile,
    conversation,
  );

  // conversationData.conversations[conversationData.conversations.length - 1] =
  //   newConversation;

  // const { error: updateError } = await supabase.from("profiles").update({
  //   builder_conversation_data: conversationData,
  // }).eq("id", profile.id);
  // if (updateError) {
  //   console.error("Error updating profile:", updateError.message);
  //   return new Response(
  //     JSON.stringify({ error: "Server Error" }),
  //     { status: 500, headers: { "Content-Type": "application/json" } },
  //   );
  // }

  const converted = streamRes.body?.pipeThrough(new TextDecoderStream())
    .pipeThrough(
      new TransformStream({
        transform: (chunk, controller) => {
          console.log(chunk);
          if (chunk.includes("data: [DONE]")) {
            controller.terminate();
            return;
          }
          const data: any[] = [];
          const lines = chunk.split("\n");
          for (const line of lines) {
            if (line.startsWith("data: ")) {
              data.push(JSON.parse(line.slice(6)));
            }
          }

          for (const d of data) {
            controller.enqueue(d.choices[0].delta.content);
          }
        },
      }),
    ).pipeThrough(new TextEncoderStream());

  return new Response(
    converted,
    {
      status: streamRes.status,
      headers: streamRes.headers,
    },
    // JSON.stringify({
    //   status: newConversation.state,
    //   message: newConversation.messages[newConversation.messages.length - 1],
    //   progress: newConversation.progress,
    // }),
    // { headers: { "content-type": "application/json" } },
  );
});
