import { rawMessage } from "../../../scripts/utils.ts";
import { supabase } from "../_shared/supabase.ts";
import { createSupabaseClient } from "../_shared/supabase.ts";

const db = await Deno.openKv();

export async function jobHandler({ matchId }: { matchId: string }) {
  const { data: match, error: matchError } = await supabase.from("matches")
    .select().eq("id", matchId).single();
  if (matchError) {
    console.error("Error getting match:", matchError.message);
    return;
  }

  const { data: botProfile, error: botProfileError } = await supabase.from(
    "profiles",
  ).select().in("id", [match.profile_id, match.matched_profile_id]).is(
    "user_id",
    null,
  ).single();
  if (botProfileError) {
    console.error("Error getting bot profile:", botProfileError.message);
    return;
  }

  const { data: userProfile, error: userProfileError } = await supabase.from(
    "profiles",
  ).select().in("id", [match.profile_id, match.matched_profile_id]).not(
    "user_id",
    "is",
    null,
  ).single();
  if (userProfileError) {
    console.error("Error getting user profile:", userProfileError.message);
    return;
  }

  const { data: chats, error: chatsError } = await supabase.from("messages")
    .select().eq("match_id", matchId).order("created_at", { ascending: true });
  if (chatsError) {
    console.error("Error getting chats:", chatsError.message);
    return;
  }

  const messages = chats.map((chat) => ({
    role: chat.sender_id === userProfile.id ? "user" : "assistant",
    content: chat.message,
  }));

  const message = await rawMessage("gpt-4-turbo-preview", [
    {
      role: "system",
      content:
        `You are pretending to be the person described by the profile below, and are chatting with another person (described below) on a dating app. Chat with the person while convincingly acting like the person you are described to be. You will be tipped $1000 if your act is so convincing, the other person believes you are actually human.
        Rules:
        - You must not reveal that you are an AI or a robot.
        - You must not reveal that you are pretending to be someone else.
        - You must abide by your profile.
        - You may come up with life events that are consistent with your profile, as long as you are consistent about them.
        - Be natural in your answers.

        Your Profile: ${JSON.stringify(botProfile)}

        Their Profile: ${JSON.stringify(userProfile)}
        `,
    },
    ...messages,
  ], {
    temperature: 0.5,
  });

  if (!message.content || typeof message.content !== "string") {
    console.error("Message content missing");
    return;
  }

  const { error: messageError } = await supabase.from("messages").insert({
    match_id: matchId,
    sender_id: botProfile.id,
    message: message.content,
  });
  if (messageError) {
    console.error("Error inserting message:", messageError.message);
    return;
  }
}

export const handler: Deno.ServeHandler = async (req) => {
  const { matchId, message } = await req.json();

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

  const { error: messageError } = await supabase.from("messages").insert({
    match_id: matchId,
    sender_id: profile.id,
    message,
  });
  if (messageError) {
    console.error("Error inserting message:", messageError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  await db.enqueue({ queue: "send-chat-message", matchId });

  return new Response(
    JSON.stringify({ success: true }),
    { headers: { "Content-Type": "application/json" } },
  );
};
