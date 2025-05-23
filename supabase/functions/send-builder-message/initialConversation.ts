import { rawMessageStream } from "../_shared/utils.ts";
import type { Database } from "../_shared/supabaseTypes.d.ts";

type InterviewUserMessageMetadata = {
  interruption: boolean;
};

function isInterviewUserMessage(
  message: unknown,
): message is InterviewUserMessageMetadata {
  return typeof message === "object" && message !== null &&
    "interruption" in message;
}

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
  - Do not mention the user's name constantly in your responses.
  
  Profile Information: {profile}

  Areas to ask about (in no particular order):
  ${
    profileQuestions.sort(() => Math.random() - 0.5).map((q) => `- ${q}`).join(
      "\n",
    )
  }`;

export async function generateInitialConversationMessage(
  profile: Database["public"]["Tables"]["profiles"]["Row"],
  messages: Database["public"]["Tables"]["interview_messages"]["Row"][],
) {
  const responseCount = messages.filter((m) => m.role === "user").length - 1;

  const res = await rawMessageStream(
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
      ...messages.map((m) => ({
        role: m.role,
        content: `${
          isInterviewUserMessage(m.metadata)
            ? m.metadata.interruption ? "<INTERRUPT> " : ""
            : ""
        }${m.content}`,
      })),
      {
        role: "system",
        content:
          `You MUST respond in one of the following formats, and include all fields listed:
        Determine if the user is likely to be done answering the question, based on how they finished their answer.
        If you do not think they are done yet, respond with just this tag to indicate we're still waiting for them to finish:

        <wait>

        Otherwise, if they are done and we're ready to move to the next question, respond with these fields:
        - thought: Your reasoning for choosing this topic and asking this question
        - topic: The topic to ask about
        - voice: A short voice script to read out to the user
        - isFollowUp: Has the topic already been covered?
        - progress: The approximate percentage of the conversation that has been completed, from 0 to 100
        - title: A short title for the message, for example: "Let's talk family" or "What about fun?", 2-3 words
        - instructions: Short clarifying instructions for what the question is asking and how to answer
        
        Provide each field in this format, no other text should be included in your message:
        <thought>thought here<voice>voice script here<instructions>instructions here<progress>80<title>title here<topic>topic here<isFollowUp>true or false`,
      },
    ],
    {
      temperature: 0,
      maxTokens: 800,
    },
  );

  return res;
}
