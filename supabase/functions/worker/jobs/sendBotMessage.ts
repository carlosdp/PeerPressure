import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import { rawMessage } from "../../_shared/utils.ts";
import logger from "../../logger.ts";

export type SendBotMessageJob = {
  matchId: string;
};

async function job(job: Job<SendBotMessageJob>) {
  logger.info(`Sending bot message for match ${job.data.matchId}`);

  const { data: match, error: matchError } = await supabase.from("matches")
    .select().eq("id", job.data.matchId).single();
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
    throw new Error(`Error getting bot profile: ${botProfileError.message}`);
  }

  const { data: userProfile, error: userProfileError } = await supabase.from(
    "profiles",
  ).select().in("id", [match.profile_id, match.matched_profile_id]).not(
    "user_id",
    "is",
    null,
  ).single();
  if (userProfileError) {
    throw new Error(`Error getting user profile: ${userProfileError.message}`);
  }

  const { data: chats, error: chatsError } = await supabase.from("messages")
    .select().eq("match_id", job.data.matchId).order("created_at", {
      ascending: true,
    });
  if (chatsError) {
    throw new Error(`Error getting chats: ${chatsError.message}`);
  }

  const messages = chats.map((chat) => ({
    role: chat.sender_id === userProfile.id ? "user" : "assistant",
    content: chat.message,
  }));

  const message = await rawMessage("openai/gpt-4-turbo-preview", [
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
    throw new Error("Message content missing");
  }

  const { error: messageError } = await supabase.from("messages").insert({
    match_id: job.data.matchId,
    sender_id: botProfile.id,
    message: message.content,
  });
  if (messageError) {
    throw new Error(`Error inserting message: ${messageError.message}`);
  }
}

export default job;
