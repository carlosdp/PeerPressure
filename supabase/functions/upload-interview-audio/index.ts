import { createSupabaseClient } from "../_shared/supabase.ts";
import { transcribe } from "../_shared/utils.ts";
import logger from "../logger.ts";
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
  let message = "";
  let progress = conversation.progress;
  const queuingStrategy = new CountQueuingStrategy({ highWaterMark: 1 });

  const textEncoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      const writableStream = new WritableStream({
        write(chunk) {
          controller.enqueue(chunk);
        },
        async close() {
          // controller.close();
          conversation.messages.push({
            role: "assistant",
            content: message,
          });
          conversation.progress = progress;
          conversation.state = progress >= 100 ? "finished" : "active";
          conversationData
            .conversations![conversationData.conversations!.length - 1] =
              conversation;

          const { error: updateError } = await supabase.from("profiles").update(
            {
              builder_conversation_data: conversationData,
            },
          ).eq("id", profile.id);
          if (updateError) {
            console.error("Error updating profile:", updateError.message);
          }
        },
      }, queuingStrategy);
      const writableStream2 = new WritableStream({
        write(chunk) {
          controller.enqueue(chunk);
        },
        close() {
          controller.close();
        },
      }, queuingStrategy);

      let audioStream: ReadableStream<Uint8Array> | undefined;

      const llmStream = body.pipeThrough(new TextDecoderStream())
        .pipeThrough(
          new TransformStream({
            transform: (chunk, controller) => {
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
                    if (tag === "message") {
                      // initiate call to 11labs w/ buffer
                      message = buffer;
                    } else if (tag === "progress") {
                      progress = parseInt(buffer);
                    }

                    tag = "";
                    buffer = "";
                  } else if (c === ">") {
                    tag = buffer;
                    console.log("TAG", tag);
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
            flush() {
              createAudioStream(message);
            },
          }),
        );

      llmStream.pipeTo(writableStream);

      function createAudioStream(text: string) {
        audioStream = new ReadableStream({
          async start(controller) {
            const audioRes = await fetch(
              "https://api.elevenlabs.io/v1/text-to-speech/XqpJyEffBCIfiqUJ5cyZ/stream", // ?output_format=pcm_16000",
              {
                method: "POST",
                body: JSON.stringify({
                  text: text,
                  model: "eleven_turbo_v2",
                }),
                headers: {
                  "Content-Type": "application/json",
                  "xi-api-key": Deno.env.get(
                    "ELEVEN_LABS_API_KEY",
                  )!,
                },
              },
            );
            const audioBody = audioRes.body;
            if (!audioBody) {
              logger.error("No audio body in response");
              controller.close();
              return;
            }

            if (audioRes.status !== 200) {
              logger.error(
                `Error from 11labs: ${audioRes.status} ${await audioRes
                  .text()}`,
              );
              controller.close();
              return;
            }

            const tag = textEncoder.encode("<audio>");
            const closeTag = textEncoder.encode("</audio>");
            const audioReader = audioBody.getReader();
            let audioResult = await audioReader.read();
            while (!audioResult.done) {
              const tagAndAudio = new Uint8Array(
                tag.length + audioResult.value.length +
                  closeTag.length,
              );
              tagAndAudio.set(tag);
              tagAndAudio.set(audioResult.value, tag.length);
              tagAndAudio.set(
                closeTag,
                tag.length + audioResult.value.length,
              );

              controller.enqueue(tagAndAudio);

              audioResult = await audioReader.read();
            }

            controller.close();
          },
        });
        audioStream.pipeTo(writableStream2);
      }
    },
  }, queuingStrategy);

  return new Response(
    stream,
    {
      headers: {
        "Content-Type": "text/event-stream",
      },
    },
  );
});
