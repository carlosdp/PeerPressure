import { rawMessage } from "../_shared/utils.ts";
import { createJob } from "../worker/job.ts";
import type { Database } from "../_shared/supabaseTypes.d.ts";

export type BuilderConversationData = {
  conversations?: {
    messages: {
      role: string;
      content: string;
      interruption?: boolean;
      topic?: string;
      followUp?: boolean;
    }[];
    state: "active" | "finished";
    progress: number;
  }[];
};

const profileQuestions = [
  "Personality Traits: What words would you use to describe yourself?",
  "Interests and Passions: What activities or topics do you feel most passionate about?",
  "Values: What are the most important values to you in a potential partner or relationship?",
  "Career and Ambitions: What are your career goals, and what do you aspire to achieve in the future?",
  "Sense of Humor: What type of humor resonates with you? Are you more into witty banter, sarcasm, or slapstick?",
  "Lifestyle: How would you describe your daily routine and lifestyle habits?",
  "Family and Relationships: What is your relationship like with your family and how important is family to you?",
  "Travel and Adventure: What are some of your favorite travel destinations or dream adventures?",
  "Cultural Background: How does your cultural background influence your perspectives and preferences in dating?",
  "Education and Intellectual Pursuits: What subjects or topics are you interested in learning more about?",
  "Relationship Goals: What are you looking for in a relationship? Are you seeking something casual, serious, or long-term?",
  "Communication Style: How do you prefer to communicate with potential partners? Are you more comfortable with texting, phone calls, or face-to-face conversations?",
  "Pet Peeves: What are some things that instantly turn you off or annoy you in a potential partner?",
  "Health and Fitness: What role does health and fitness play in your life? Do you have any specific fitness goals or activities you enjoy?",
  "Music and Entertainment: What type of music or entertainment do you enjoy? Are you a concert-goer, movie buff, or theater enthusiast?",
  "Food and Dining: What are your favorite cuisines or types of food? Are you an adventurous eater or do you prefer sticking to familiar dishes?",
  "Social Life: How do you like to spend your time with friends and in social settings?",
  "Relationship History: What have been your experiences in past relationships, and what have you learned from them?",
  "Future Aspirations: Where do you see yourself in the next few years, both personally and professionally?",
];

const PROMPT =
  `You are an expert dating coach that is helping a client create their dating profile. Use the profile information below to ask the client several short questions to get to know them better and their interests, so that you can create prompts for a dating profile for them.

  Rules:
  - Only ask for clarifying questions on things that would be potentially interesting to a potential date. For example, details about how someone's job works is not interesting.
  - NEVER repeat the same (or basically the same) question.
  - When you have a good answer in an area, move on to another area in a natural way. Each area should have a maximum of two follow-up questions.
  - You only have 10 responses maximum to gather information for the profile, so don't linger on a topic too long and cover as much ground as possible.
  - If the user's message is marked <INTERRUPT>, that means they interrupted before your previous message was finished reading. Assume the user did not finish reading the previous message.
  
  Profile Information: {profile}

  Areas to ask about (in no particular order):
  ${
    profileQuestions.sort(() => Math.random() - 0.5).map((q) => `- ${q}`).join(
      "\n",
    )
  }`;

export async function generateInitialConversationMessage(
  profile: Database["public"]["Tables"]["profiles"]["Row"],
  conversation: NonNullable<BuilderConversationData["conversations"]>[number],
) {
  const responseCount =
    conversation.messages.filter((m) => m.role === "user").length - 1;
  const targetResponses = 10;
  const newConversationMessage: NonNullable<
    BuilderConversationData["conversations"]
  >[number]["messages"][number] = {
    role: "assistant",
    content: "",
  };

  if (responseCount >= targetResponses) {
    conversation.state = "finished";
    newConversationMessage.content = "Thank you! Working on your profile...";

    await createJob("buildProfile", { profileId: profile.id });

    return conversation;
  }

  const newMessage = await rawMessage(
    "openai/gpt-4-turbo-preview",
    [
      {
        role: "system",
        content: PROMPT.replace(
          "{profile}",
          JSON.stringify({
            name: profile.first_name,
            gender: profile.gender,
            location: profile.display_location,
            age: new Date().getFullYear() -
              new Date(profile.birth_date).getFullYear(),
          }),
        ),
      },
      {
        role: "system",
        content:
          `${responseCount}/10 responses used. Based on the conversation, decide the next area to ask about, and ask a question. You must NOT repeat a topic already covered. You can only send the user ONE message at a time.`,
      },
      ...conversation.messages.map((m) => ({
        role: m.role,
        content: `${m.interruption ? "<INTERRUPT> " : ""}${m.content}`,
      })),
    ],
    {
      temperature: 0,
      maxTokens: 500,
      toolChoice: { type: "function", function: { name: "sendMessage" } },
      tools: [
        {
          type: "function",
          function: {
            name: "sendMessage",
            description:
              "Send a message to the user, this function MUST be used if you want to talk to the user",
            parameters: {
              type: "object",
              required: ["thought", "topic", "message", "progress"],
              properties: {
                thought: {
                  type: "string",
                  description:
                    "Your reasoning for choosing this topic and asking this question",
                },
                topic: {
                  type: "string",
                  description: "The topic to ask about",
                },
                isFollowUp: {
                  type: "boolean",
                  description: "Has the topic already been covered?",
                },
                progress: {
                  type: "number",
                  description:
                    "The approximate percentage of the conversation that has been completed, from 0 to 100",
                },
                message: {
                  type: "string",
                  description: "The message to send",
                },
              },
            },
          },
        },
      ],
    },
  );

  console.log("New message:", newMessage);

  if (newMessage.content || !newMessage.tool_calls) {
    throw new Error("Unexpected message content");
  }

  if (
    newMessage.tool_calls[0]?.function.name === "sendMessage"
  ) {
    const args = JSON.parse(newMessage.tool_calls[0].function.arguments);
    newConversationMessage.content = args.message;
    newConversationMessage.topic = args.topic;
    newConversationMessage.followUp = args.isFollowUp;
    conversation.progress = args.progress;
  } else {
    throw new Error("No message content");
  }

  conversation.messages.push(newConversationMessage);

  return conversation;
}
