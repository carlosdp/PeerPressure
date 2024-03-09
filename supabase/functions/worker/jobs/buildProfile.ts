import type { Job } from "npm:pg-boss@9.0.3";
import { supabase } from "../../_shared/supabase.ts";
import type { BuilderConversationData } from "../../send-builder-message/handler.ts";
import { rawMessage } from "../../_shared/utils.ts";
import logger from "../../logger.ts";
import type { Photo } from "../../_shared/supabaseJsonTypes.d.ts";
import { generateProfile } from "./generateProfile.ts";

export type BuildProfileJob = {
  profileId: string;
};

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, _) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.readAsDataURL(blob);
  });
}

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

  const photoKeys = profile.available_photos as Photo[];

  const photos = await Promise.all(photoKeys.map(async (photoKey) => {
    const { data: photo, error: photoError } = await supabase.storage.from(
      "photos",
    ).download(photoKey.key);
    if (photoError) {
      console.error("Error getting photo:", photoError.message);
      throw photoError;
    }

    const dataUrl = await blobToBase64(photo);

    return { key: photoKey.key, dataUrl };
  }));

  // Pre process user photos, since GPT-4 Vision preview does not yet support tool calls
  const photoMessage = await rawMessage("gpt-4-vision-preview", [
    {
      role: "system",
      content:
        `The following are photos provided by a user to a dating app. Given the images provided, write a short description of the image and what the user is doing in the photo. Make sure to describe if the user is with other people in the photo, and how prominent they are in the photo, so that we can determine if it is a good representative image for people trying to figure out what the user looks like.
        
        Respond in the following JSON array format:
        [{ key: "<photo key here>", description: "<description here>" }, ...]`,
    },
    {
      role: "user",
      content: photos.flatMap((photo) => [
        {
          type: "text",
          text: `Key: ${photo.key}`,
        },
        {
          type: "image_url",
          image_url: { url: photo.dataUrl, detail: "low" },
        },
      ]),
    },
    {
      role: "system",
      content: "Respond in pure JSON only",
    },
  ], {
    maxTokens: 1000,
    temperature: 0,
  });

  if (!photoMessage.content || typeof photoMessage.content !== "string") {
    console.error("No photo message content");
    return;
  }
  console.log("Photo message:", photoMessage.content);

  const photoDescriptions = JSON.parse(
    photoMessage.content.replaceAll("```json", "").replaceAll("```", ""),
  );
  const photosWithDescriptions = (profile.available_photos as Photo[]).map((
    photo,
  ) => ({
    key: photo.key,
    description: photoDescriptions.find((d: { key: string }) =>
      d.key === photo.key
    )?.description,
  }));

  const messages = [
    {
      role: "system",
      content: "Construct a profile using the following conversation:",
    },
    ...conversation.messages,
  ];

  const blocks = await generateProfile(
    profile,
    photosWithDescriptions,
    messages,
  );

  const { error: updateError } = await supabase.from("profiles").update({
    blocks,
    available_photos: photosWithDescriptions,
  }).eq("id", profile.id);
  if (updateError) {
    console.error("Error updating profile:", updateError.message);
    return;
  }
}

export default job;
