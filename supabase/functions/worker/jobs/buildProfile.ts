import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import type { BuilderConversationData } from "../../send-builder-message/handler.ts";
import logger from "../../logger.ts";
import type { Photo } from "../../_shared/supabaseJsonTypes.d.ts";
import { generateProfile } from "./generateProfile.ts";

export type BuildProfileJob = {
  profileId: string;
};

async function job(job: Job<BuildProfileJob>) {
  logger.info(`Building profile ${job.data.profileId}`);

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

  const conversationData = profile
    .builder_conversation_data as BuilderConversationData;
  const conversation = conversationData.conversations?.findLast((c) =>
    c.state === "finished"
  );

  if (!conversation) {
    console.error("No finished conversation");
    return;
  }

  const photos = profile.available_photos as Photo[];

  const messages = [
    {
      role: "system",
      content: "Construct a profile using the following conversation:",
    },
    ...conversation.messages,
  ];

  const blocks = await generateProfile(
    profile,
    photos,
    messages,
  );

  const { error: updateError } = await supabase.from("profiles").update({
    blocks,
  }).eq("id", profile.id);
  if (updateError) {
    console.error("Error updating profile:", updateError.message);
    return;
  }
}

export default job;
