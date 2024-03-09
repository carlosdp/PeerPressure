import fs from "https://deno.land/std@0.177.1/node/fs.ts";
import {
  Database,
  Json,
} from "../supabase/functions/_shared/supabaseTypes.d.ts";
import { generateProfile } from "../supabase/functions/worker/jobs/generateProfile.ts";

const profile: Database["public"]["Tables"]["profiles"]["Row"] = {
  id: "0",
  user_id: "0",
  first_name: "Carlos",
  gender: "male",
  display_location: "Brooklyn, NY",
  location: "",
  available_photos: [] as Json,
  photo_keys: [] as Json,
  biographical_data: {} as Json,
  birth_date: "19920720T00:00:00.000Z",
  blocks: [] as Json,
  builder_conversation_data: {} as Json,
  preferences: {} as Json,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
};

const photos = [
  {
    "key":
      "571F555C-ACDA-49B3-A653-BC9A098E431D/profile/7640F5A1-F455-4A6B-B5E4-E1068C89F4D3.jpg",
    "description":
      "The user is standing indoors wearing a formal black tuxedo with a bow tie. He is facing the camera with a neutral expression. The background shows a well-lit room with a chandelier and artwork on the walls. This photo provides a clear view of the user's appearance.",
  },
  {
    "key":
      "571F555C-ACDA-49B3-A653-BC9A098E431D/profile/299E21C1-2C38-4131-9004-5764B07C2AA7.jpg",
    "description":
      "The user is outdoors, leaning against a metal railing with a city street in the background. He is wearing a blue blazer over a white shirt and has a relaxed, friendly expression. This image offers a good representation of the user in a casual setting.",
  },
  {
    "key":
      "571F555C-ACDA-49B3-A653-BC9A098E431D/profile/3D2D5D46-FE02-4A19-A654-E1D3AC57F0E9.jpg",
    "description":
      "The user is seated outdoors with a slight smile, wearing a grey shirt over a white undershirt, paired with blue trousers. The background includes a metallic structure, possibly part of a vehicle or urban setting. This photo provides a good view of the user in a relaxed pose.",
  },
  {
    "key":
      "571F555C-ACDA-49B3-A653-BC9A098E431D/profile/DC7DD333-B015-4C0B-A359-EEBFDE739251.jpg",
    "description":
      "The user is on a boat with two other people, a woman to his left and another woman to his right. He is in the center of the photo, wearing a dark shirt and sunglasses, with the ocean and skyline in the background. While the user is clearly visible, the presence of others may slightly distract from focusing solely on the user.",
  },
];

const conversation = {
  "state": "finished",
  "messages": [
    { "role": "assistant", "content": "Ready to get started?" },
    { "role": "user", "content": "Ready" },
    {
      "role": "assistant",
      "content":
        "What are some of your favorite hobbies or activities you like to do in your free time?",
    },
    { "role": "user", "content": "I like cooking, reading, and sailing" },
    {
      "role": "assistant",
      "content":
        "That's great! What kind of cuisine do you enjoy cooking the most?",
    },
    { "role": "user", "content": "Mostly French cuisine, sometimes Cuban" },
    {
      "role": "assistant",
      "content":
        "What's your current career, and what do you enjoy most about your job?",
    },
    {
      "role": "user",
      "content": "I’m a software engineer, I love solving hard problems",
    },
    {
      "role": "assistant",
      "content":
        "What's most important to you in your life? Your career, family, friends, hobbies, or something else?",
    },
    {
      "role": "user",
      "content": "I’m super career ambitious, but family does come first ",
    },
    {
      "role": "assistant",
      "content": "What qualities are you looking for in a partner?",
    },
    {
      "role": "user",
      "content":
        "I’m looking for someone smart, funny, and who likes to travel ",
    },
    {
      "role": "assistant",
      "content":
        "Do you enjoy traveling, and if so, what are some of your favorite destinations?",
    },
    {
      "role": "user",
      "content":
        "Yes, I’ve been to Europe a lot recently, my favorite city there is Lisbon, and I also really like Barcelona",
    },
    {
      "role": "assistant",
      "content": "What are you most passionate about outside of work?",
    },
    {
      "role": "user",
      "content":
        "I like learning about space, and keeping up with technology advances",
    },
    {
      "role": "assistant",
      "content":
        "What kind of books do you enjoy reading in your leisure time?",
    },
    { "role": "user", "content": "Mostly sci-fi and ww2 history " },
    { "role": "assistant", "content": "Thank you! Working on your profile..." },
  ],
};

const messages = [
  {
    role: "system",
    content: "Construct a profile using the following conversation:",
  },
  ...conversation.messages,
];

console.log("Generating profile...");

const blocks = await generateProfile(
  profile,
  photos,
  messages,
);

console.log("Writing to file...");

fs.writeFileSync(
  "artifacts/profileBlocks.json",
  JSON.stringify(blocks, null, 2),
);
