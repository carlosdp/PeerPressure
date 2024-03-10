import { supabase } from "./_shared/supabase.ts";
import { rawMessage } from "./_shared/utils.ts";

const db = await Deno.openKv();

export async function matchJob() {
  const { data: pendingMatches, error } = await supabase.rpc(
    "get_pending_bot_matches",
  );
  if (error) {
    console.error("Error fetching pending matches:", error);
    return;
  }

  for (const match of pendingMatches) {
    const tracker = await db.get<{ matchTime: number }>([
      "matchTracker",
      match.id,
    ]);

    if (tracker.value) {
      // Check if it's time to match yet
      if (Date.now() >= tracker.value.matchTime) {
        // match them
        const { error: matchError } = await supabase.from("matches").update({
          match_accepted_at: new Date().toISOString(),
        }).eq("id", match.id);
        if (matchError) {
          console.error("Error updating match:", matchError.message);
        }

        await db.delete(["matchTracker", match.id]);
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
        console.error("Error getting bot profile:", botProfileError.message);
        return;
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
        console.error("Error getting user profile:", userProfileError.message);
        return;
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

        console.log("Will match in", delay / 1000 / 60 / 60, "hours");

        await db.set(["matchTracker", match.id], {
          matchTime,
        });
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
