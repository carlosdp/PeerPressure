const client = {
  post: async (endpoint: string, data: any, headers: any) => {
    const res = await fetch(`https://api.openai.com/v1/${endpoint}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...headers.headers,
      },
      body: JSON.stringify(data),
    });

    return {
      status: res.status,
      statusText: res.statusText,
      data: await res.json(),
    };
  },
};

export type OpenAIMessage =
  & { role: string; name?: string }
  & (
    | { content: string; tool_calls?: null }
    | {
      content: null;
      tool_calls: { name: string; function: { arguments: any } }[];
    } // eslint-disable-line @typescript-eslint/no-explicit-any
    | { content: { type: "image_url"; image_url: string }[] }
  );

export type OpenAIToolDefinition = {
  type: "function";
  function: {
    name: string;
    description: string;
    parameters: any; // eslint-disable-line @typescript-eslint/no-explicit-any
  };
};

export const message = async (
  model: string,
  messages: OpenAIMessage[],
  maxTokens: number,
  temperature?: number,
) => {
  const data = {
    model,
    messages,
    temperature: temperature || 0,
    max_tokens: maxTokens,
  };
  try {
    const res = await client.post("/chat/completions", data, {
      headers: {
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
    });

    if (res.status !== 200) {
      throw new Error(`OpenAI API error: ${res.statusText}`);
    }

    return res.data.choices[0].message.content.trim();
  } catch (error) {
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};

export type RawMessageOptions = {
  maxTokens?: number;
  temperature?: number;
  tools?: OpenAIToolDefinition[];
  toolChoice?: { type: "function"; function: { name: string } };
};

export const rawMessage = async (
  model: string,
  messages: OpenAIMessage[],
  options?: RawMessageOptions,
): Promise<OpenAIMessage> => {
  try {
    const res = await client.post(
      "/chat/completions",
      {
        model,
        messages,
        temperature: options?.temperature || 0,
        max_tokens: options?.maxTokens,
        tools: options?.tools,
        tool_choice: options?.toolChoice,
      },
      {
        headers: {
          Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
        },
      },
    );

    if (res.status !== 200) {
      throw new Error(`OpenAI API error: ${res.statusText}`);
    }

    return res.data.choices[0].message;
  } catch (error) {
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};

export const embedding = async (text: string) => {
  const embeddingRes = await client.post(
    "/embeddings",
    {
      model: "text-embedding-ada-002",
      input: [text],
    },
    {
      headers: {
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
    },
  );

  return embeddingRes.data.data[0].embedding;
};

export const transcribe = async (audio: Blob): Promise<string> => {
  const formData = new FormData();
  formData.append("file", audio);
  formData.append("model", "whisper-1");
  formData.append("language", "en");
  formData.append("response_format", "json");
  formData.append("temperature", "0");

  const transcriptionRes = await client.post(
    "/audio/transcriptions",
    formData,
    {
      headers: {
        "Content-Type": "multipart/form-data",
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
    },
  );

  console.log(`Transcription response: ${transcriptionRes.data}`);

  return transcriptionRes.data.text;
};

export const generateImage = async (
  prompt: string,
  size?: string,
  style?: "vivid" | "natural",
): Promise<ArrayBuffer> => {
  const res = await client.post(
    "images/generations",
    {
      prompt,
      model: "dall-e-3",
      size: size ?? "1024x1024",
      style,
    },
    {
      headers: {
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
    },
  );

  console.log(`Image generation response: ${JSON.stringify(res.data)}`);

  const url = res.data.data[0].url;

  const imageRes = await fetch(url).then((r) => r.arrayBuffer());

  return imageRes;
};
