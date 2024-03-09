import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import logger from "../../logger.ts";
import type { Photo } from "../../_shared/supabaseJsonTypes.d.ts";
import { generateProfile } from "./generateProfile.ts";

export type ChangeProfileJob = {
  profileId: string;
  changes: string;
};

async function job(job: Job<ChangeProfileJob>) {
  logger.info(`Changing profile ${job.data.profileId}: ${job.data.changes}`);

  const { data: profile, error: profileError } = await supabase.from(
    "profiles",
  )
    .select().eq("id", job.data.profileId).single();
  if (profileError) {
    console.error("Error getting profile:", profileError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const photos = profile.available_photos as Photo[];

  const blocks = await generateProfile(profile, photos, [
    {
      role: "system",
      content:
        `Edit the profile to make the following changes:\n${job.data.changes}`,
    },
  ]);

  const { error: updateError } = await supabase.from("profiles").update({
    blocks,
  }).eq("id", profile.id);
  if (updateError) {
    console.error("Error updating profile:", updateError.message);
    return;
  }
}

export default job;
