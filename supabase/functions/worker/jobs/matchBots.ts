import type { Job } from "npm:pg-boss@9.0.3";
import type { MatchData } from "../../_shared/supabaseJsonTypes.d.ts";
import { supabase } from "../../_shared/supabase.ts";
import { rawMessage } from "../../_shared/utils.ts";
import logger from "../../logger.ts";

async function job(_job: Job) {
  const { data: pendingMatches, error } = await supabase.rpc(
    "get_pending_bot_matches",
  );
  if (error) {
    throw new Error(`Error fetching pending matches: ${error}`);
  }

  for (const match of pendingMatches) {
    const matchData = match.data as MatchData;

    if (matchData.matchTime) {
      // Check if it's time to match yet
      if (Date.now() >= matchData.matchTime) {
        // match them
        const { error: matchError } = await supabase.from("matches").update({
          match_accepted_at: new Date().toISOString(),
        }).eq("id", match.id);
        if (matchError) {
          throw new Error(`Error updating match: ${matchError.message}`);
        }
      }
    } else {
      // New match, come up with a match decision and timing
      const { data: botProfile, error: botProfileError } = await supabase.from(
        "profiles",
      ).select().in("id", [match.profile_id, match.matched_profile_id]).is(
        "user_id",
        null,
      ).single();
      if (botProfileError) {
        throw new Error(`Error getting bot profile: botProfileError.message`);
      }

      const { data: userProfile, error: userProfileError } = await supabase
        .from(
          "profiles",
        ).select().in("id", [match.profile_id, match.matched_profile_id]).not(
          "user_id",
          "is",
          null,
        ).single();
      if (userProfileError) {
        throw new Error(
          `Error getting user profile: ${userProfileError.message}`,
        );
      }

      const message = await rawMessage("openai/gpt-4-turbo-preview", [
        {
          role: "system",
          content:
            "You are an expert dating matcher. Based on the provided profiles, decide whether they should be matched or not.",
        },
        {
          role: "user",
          content: `Profile 1: ${JSON.stringify(botProfile)}\nProfile 2: ${
            JSON.stringify(userProfile)
          }`,
        },
        {
          role: "system",
          content: "Respond with 'match' or 'no match' only.",
        },
      ], {
        temperature: 0.1,
      });

      if (message.content === "match") {
        // ok, we've decided to match, now let's come up with a time delay from now
        const delay = Math.floor(Math.random() * 60 * 60 * 1000 * 48); // 0 - 48 hours
        const matchTime = Date.now() + delay;

        logger.debug("Will match in", delay / 1000 / 60 / 60, "hours");

        const { error: updateError } = await supabase.from("matches").update({
          data: {
            ...matchData,
            matchTime,
          },
        }).eq("id", match.id);

        if (updateError) {
          throw new Error(`Error updating match: ${updateError.message}`);
        }
      } else {
        await supabase.from("matches").update({
          match_rejected_at: new Date().toISOString(),
        })
          .eq(
            "id",
            match.id,
          );
      }
    }
  }
}

export default job;
