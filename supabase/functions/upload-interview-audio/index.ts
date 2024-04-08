import { createSupabaseClient } from "../_shared/supabase.ts";
import { transcribe } from "../_shared/utils.ts";
import logger from "../logger.ts";
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
  const body = streamRes.body;
  if (!body) {
    logger.error("No body in stream response");

    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let tag = "";
  let buffer = "";

  const textEncoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      console.log("starting stream");
      const llmStream = body.pipeThrough(new TextDecoderStream())
        .pipeThrough(
          new TransformStream({
            transform: (chunk, controller) => {
              console.log(chunk);
              if (chunk.includes("data: [DONE]")) {
                console.log("DONE WITH LLM");
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
                const content = d.choices[0].delta.content;

                for (const c of content) {
                  if (c === "<") {
                    tag = "";
                    buffer = "";
                  } else if (c === ">") {
                    tag = buffer;
                    buffer = "";
                  } else {
                    buffer += c;
                  }
                }

                controller.enqueue(
                  textEncoder.encode(content),
                );
              }
            },
            async flush(controller) {
              console.log("DONE WITH LLM, calling 11labs");
              controller.enqueue(textEncoder.encode("<audio>"));

              const audioRes = await fetch(
                "https://api.elevenlabs.io/v1/text-to-speech/iP95p4xoKVk53GoZ742B/stream", // ?output_format=pcm_24000",
                {
                  method: "POST",
                  body: JSON.stringify({
                    text: buffer,
                    // model: 'eleven_turbo_v2',
                  }),
                  headers: {
                    "Content-Type": "application/json",
                    "xi-api-key": Deno.env.get("ELEVEN_LABS_API_KEY")!,
                  },
                },
              );
              const audioBody = audioRes.body;
              if (!audioBody) {
                logger.error("No audio body in response");
                controller.terminate();
                return;
              }

              if (audioRes.status !== 200) {
                logger.error(
                  `Error from 11labs: ${audioRes.status} ${await audioRes
                    .text()}`,
                );
                controller.terminate();
                return;
              }

              const audioReader = audioBody.getReader();
              let audioResult = await audioReader.read();
              while (!audioResult.done) {
                console.log(audioResult.value);
                controller.enqueue(audioResult.value);
                audioResult = await audioReader.read();
              }
              console.log("DONE WITH 11LABS");
            },
          }),
        );

      const writableStream = new WritableStream({
        write(chunk) {
          controller.enqueue(chunk);
        },
        close() {
          controller.close();
        },
      });

      llmStream.pipeTo(writableStream);
    },
  });

  return new Response(
    stream,
    {
      headers: {
        "Content-Type": "text/event-stream",
      },
    },
  );
});
