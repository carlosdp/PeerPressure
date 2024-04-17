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

  const lastAssistantMessageMetadata = messages.findLast((m) =>
    m.role === "assistant"
  )?.metadata;
  let progress = isInterviewAssistantMessageData(lastAssistantMessageMetadata)
    ? lastAssistantMessageMetadata.progress ?? 0
    : 0;
  let cancelled = false;
  let audioStream: ReadableStream<Uint8Array> | undefined;

  const stream = new ReadableStream({
    start(controller) {
      const audioOutputStream = new WritableStream({
        write(chunk) {
          controller.enqueue(chunk);
        },
        close() {
          controller.close();
        },
      });

      const reader = body.getReader();
      let buffer = "";
      let tag = "";
      let title = "";
      let topic = "";
      let instructions = "";
      let message = "";
      let waiting = false;

      function processCurrentTag() {
        if (tag === "voice") {
          // initiate call to 11labs w/ buffer
          message = buffer;

          if (!waiting && !cancelled) {
            createAudioStream(message);
          }
        } else if (tag === "progress") {
          console.log("PROGRESS", buffer);
          const intProgress = parseInt(buffer);
          if (!isNaN(intProgress)) {
            progress = intProgress;
          } else {
            console.error("Invalid progress value:", buffer);
          }
        } else if (tag === "title") {
          title = buffer;
        } else if (tag === "topic") {
          topic = buffer;
        } else if (tag === "instructions") {
          instructions = buffer;
        }

        tag = "";
        buffer = "";
      }

      async function readStream() {
        while (true) {
          const { done, value } = await reader.read();
          if (done) {
            break;
          }
          const chunk = new TextDecoder().decode(value);
          if (chunk.includes("data: [DONE]")) {
            console.log("DONE WITH LLM");
            processCurrentTag();
            break;
          }
          const lines = chunk.split("\n");
          for (const line of lines) {
            if (line.startsWith("data: ")) {
              const data = JSON.parse(line.slice(6));
              const content = data.choices[0].delta.content;

              for (const c of content) {
                if (c === "<") {
                  processCurrentTag();
                } else if (c === ">") {
                  tag = buffer;
                  console.log("TAG", tag);
                  buffer = "";

                  if (tag === "wait") {
                    waiting = true;
                    console.log("Waiting for user to finish");
                    controller.close();
                    return;
                  }
                } else {
                  buffer += c;
                }
              }
            }
          }
        }

        if (cancelled || waiting || message.length === 0) {
          return;
        }

        const { error: insertError } = await supabase.from(
          "interview_messages",
        ).insert({
          interview_id: activeInterview!.id,
          role: "assistant",
          content: message,
          metadata: {
            title,
            topic,
            instructions,
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
      }

      readStream();

      async function createAudioStream(text: string) {
        const audioRes = await fetch(
          "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM/stream",
          {
            method: "POST",
            body: JSON.stringify({
              text: text,
              model_id: "eleven_turbo_v2",
              voice_settings: {
                stability: 0.35,
                similarity_boost: 0.6,
              },
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

        audioBody.pipeTo(audioOutputStream);
      }
    },
    cancel() {
      audioStream?.cancel();
      cancelled = true;
    },
  });

  return new Response(
    stream,
    {
      headers: {
        "Content-Type": "audio/mp3",
      },
    },
  );
});
