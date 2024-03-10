import { OpenAIMessage, rawMessage } from "../../_shared/utils.ts";
import type { Database } from "../../_shared/supabaseTypes.d.ts";
import type { Photo } from "../../_shared/supabaseJsonTypes.d.ts";

const CONSTRUCTION_PROMPT =
  `You are an expert dating profile creator that helps clients construct a fun, whimsical dating profile that helps them attract the right person for them. Take into account the guidelines below when constructing a dating profile for the given client.

  Guidelines:
  - Profiles are expressed as a list of "blocks" of different types, organized in a vertical profile on mobile phones
  - There should be about 5-7 blocks in the profile.
  - The first block should always be a profile photo, on its own.
  - The rest of the blocks should alternate between different types of blocks, ideally not having the same block type twice in a row.

  photo blocks:
  - The first profile photo should always be the best photo that makes the client look attractive and approachable. Ideally, profile photos show only the client, or they take up most of the frame, so suitors know which person they are in the photo easily.
  - The next photo shown should be "social proof", the best photo that shows the client hanging out with friends or otherwise shows them off doing something social or at least fun.
  - The rest of the photos should be the next best photos that will make the client look attractive and friendly, matching up similar ones in the same block.
  - It is better to show less photos than use a photo that will not make the client look good. For example, photos that don't feature the client in the first place.

  gas blocks:
  - Match "gas" blocks up with relevant photos provided when possible
  - Emojis used should always be somewhere within the text, NEVER at the beginning of the text
  - Gas should be written from the perspective of a college-aged friend who is trying to sell their friend to a potential suitor by talking them up, example:
  "Jake is a Miami-based real-estate agent that likes to cook 👨‍🍳 (😩). In his free time, he also likes to go goldfing 🏌️‍♂️ and read books 📖."
  "He's looking for someone who is smart, funny, and would like to travel with him! If you like the beaches of the Bahamas, or the skiing in Aspen, this might be your guy! 😍"

  Profile Information: {profile}
  Photos: {photos}`;

export async function generateProfile(
  profile: Database["public"]["Tables"]["profiles"]["Row"],
  photos: Photo[],
  messages: OpenAIMessage[],
) {
  const constructMessage = await rawMessage("openai/gpt-4-turbo-preview", [
    {
      role: "system",
      content: CONSTRUCTION_PROMPT.replace(
        "{profile}",
        JSON.stringify({
          name: profile.first_name,
          gender: profile.gender,
          location: profile.display_location,
          age: new Date(profile.birth_date).getFullYear() -
            new Date().getFullYear(),
        }),
      ).replace("{photos}", JSON.stringify(photos)),
    },
    ...messages,
  ], {
    temperature: 1,
    maxTokens: 2000,
    toolChoice: { type: "function", function: { name: "construct" } },
    tools: [
      {
        type: "function",
        function: {
          name: "construct",
          description: "Construct the final profile blocks",
          parameters: {
            type: "object",
            properties: {
              blocks: {
                oneOf: [
                  {
                    type: "object",
                    description: "A set of photos from the user's collection",
                    required: ["photo"],
                    properties: {
                      photo: {
                        type: "object",
                        required: ["images"],
                        properties: {
                          images: {
                            type: "array",
                            items: {
                              type: "object",
                              required: ["key"],
                              properties: {
                                key: {
                                  type: "string",
                                  description: "The photo key",
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                  {
                    type: "object",
                    description:
                      "A paragraph of text telling potential suitors something exciting about the client's personality, character, or life. Should be in a fun, whimsical, approachable tone and use jokes / puns / wordplay when possible. Use of emojis is encouraged. Should be written in the third person.",
                    required: ["gas"],
                    properties: {
                      gas: {
                        type: "object",
                        required: ["text"],
                        properties: {
                          text: {
                            type: "string",
                            description:
                              "The text, feel free to use emojis and markdown for bolding/italics etc.",
                          },
                        },
                      },
                    },
                  },
                ],
              },
            },
          },
        },
      },
    ],
  });

  if (constructMessage.content || !constructMessage.tool_calls) {
    console.error("No construct message tool call");
    return;
  }

  console.log(constructMessage.tool_calls[0].function.arguments);

  const args = JSON.parse(constructMessage.tool_calls[0].function.arguments);

  return args.blocks;
}
