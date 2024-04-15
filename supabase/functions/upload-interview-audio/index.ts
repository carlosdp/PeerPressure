import { createSupabaseClient } from "../_shared/supabase.ts";
import { transcribe } from "../_shared/utils.ts";
import logger from "../logger.ts";
import {
  generateInitialConversationMessage,
} from "../send-builder-message/initialConversation.ts";

type InterviewAssistantMessageData = {
  progress?: number;
};

function isInterviewAssistantMessageData(
  data: unknown,
): data is InterviewAssistantMessageData {
  return typeof data === "object" && data !== null;
}

Deno.serve(async (req) => {
  const { text, audio, interruption } = await req.json();

  const supabase = createSupabaseClient(req.headers.get("Authorization")!);

  let transcription: string;

  if (audio) {
    const audioBlob = await fetch(audio).then((res) => res.blob());
    transcription = await transcribe(audioBlob);
  } else if (text) {
    transcription = text;
  } else {
    return new Response(
      JSON.stringify({ error: "No text or audio provided" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (transcription.length < 3) {
    return new Response(
      JSON.stringify({ error: "Transcription empty" }),
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

  const { data: interview, error: interviewError } = await supabase.rpc(
    "active_interview_for_profile",
    { profile_id: profile.id },
  );
  if (interviewError) {
    console.error("Error getting interview:", interviewError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let activeInterview = interview.length > 0 ? interview[0] : null;

  if (!activeInterview) {
    const { data: newInterview, error: newInterviewError } = await supabase
      .from("interviews").insert({
        profile_id: profile.id,
      }).select().single();
    if (newInterviewError) {
      console.error("Error creating interview:", newInterviewError.message);
      return new Response(
        JSON.stringify({ error: "Server Error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    activeInterview = newInterview;
  }

  if (!activeInterview) {
    console.error("No active interview");
    return new Response(
      JSON.stringify({ error: "Server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: messages, error: messagesError } = await supabase.from(
    "interview_messages",
  ).select().eq("interview_id", activeInterview.id);
  if (messagesError) {
    console.error("Error getting messages:", messagesError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  if (messages.length === 0) {
    const { data: newMessage, error: insertError } = await supabase.from(
      "interview_messages",
    )
      .insert({
        interview_id: activeInterview.id,
        role: "assistant",
        content: "Ready to get started?",
      }).select().single();
    if (insertError) {
      console.error("Error inserting message:", insertError.message);
      return new Response(
        JSON.stringify({ error: "Server Error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    messages.push(newMessage);
  }

  const { data: newMessage, error: newMessageError } = await supabase.from(
    "interview_messages",
  ).insert({
    interview_id: activeInterview.id,
    role: "user",
    content: transcription,
    metadata: {
      // it's only an interruption if the last message was not from the user,
      // from the LLM's perspective
      interruption: interruption &&
        messages[messages.length - 1].role !==
          "user",
    },
  }).select().single();
  if (newMessageError) {
    console.error("Error inserting message:", newMessageError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  messages.push(newMessage);

  const streamRes = await generateInitialConversationMessage(
    profile,
    messages,
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
  const lastAssistantMessageMetadata = messages.findLast((m) =>
    m.role === "assistant"
  )?.metadata;
  let progress = isInterviewAssistantMessageData(lastAssistantMessageMetadata)
    ? lastAssistantMessageMetadata.progress ?? 0
    : 0;
  const queuingStrategy = new CountQueuingStrategy({ highWaterMark: 1 });
  let cancelled = false;
  let waiting = false;

  const textEncoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      const writableStream = new WritableStream({
        write(chunk) {
          controller.enqueue(chunk);
        },
        async close() {
          // controller.close();
          if (cancelled || waiting) {
            return;
          }

          const { error: insertError } = await supabase.from(
            "interview_messages",
          ).insert({
            interview_id: activeInterview!.id,
            role: "assistant",
            content: message,
            metadata: {
              progress,
            },
          });
          if (insertError) {
            console.error("Error inserting message:", insertError.message);
            return;
          }

          if (progress >= 100) {
            const { error: updateError } = await supabase.from("interviews")
              .update({
                completed_at: new Date().toISOString(),
              }).eq("id", activeInterview!.id);
            if (updateError) {
              console.error(
                "Error updating interview for completion:",
                updateError.message,
              );
              return;
            }
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
              const data: { choices: { delta: { content: string } }[] }[] = [];
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
                    if (tag === "voice") {
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

                    if (tag === "wait") {
                      waiting = true;
                    }
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
              if (!waiting && !cancelled) {
                createAudioStream(message);
              } else {
                controller.close();
              }
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
    cancel() {
      cancelled = true;
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
