const apiUrls = {
  openai: {
    url: "https://api.openai.com/v1",
    keyEnv: "OPENAI_API_KEY",
  },
  together: {
    url: "https://api.together.xyz/v1",
    keyEnv: "TOGETHER_API_KEY",
  },
  fal: {
    url: "https://fal.run",
    keyEnv: "FAL_API_KEY",
  },
} as const;

export type ApiModel = `${keyof typeof apiUrls}/${string}`;

const client = {
  post: async (
    api: keyof typeof apiUrls,
    endpoint: string,
    data: any,
    headers?: any,
  ) => {
    const res = await fetch(`${apiUrls[api].url}/${endpoint}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get(apiUrls[api].keyEnv)}`,
        ...headers?.headers ?? {},
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
      tool_calls: {
        type: "function";
        function: { name: string; arguments: any };
      }[];
    } // eslint-disable-line @typescript-eslint/no-explicit-any
    | {
      content: ({ type: "text"; text: string } | {
        type: "image_url";
        image_url: { url: string; detail?: "low" | "high" };
      })[];
    }
  );

export type OpenAIToolDefinition = {
  type: "function";
  function: {
    name: string;
    description: string;
    parameters: any; // eslint-disable-line @typescript-eslint/no-explicit-any
  };
};

export type RawMessageOptions = {
  maxTokens?: number;
  temperature?: number;
  tools?: OpenAIToolDefinition[];
  toolChoice?: { type: "function"; function: { name: string } };
};

export const rawMessage = async (
  model: ApiModel,
  messages: OpenAIMessage[],
  options?: RawMessageOptions,
): Promise<OpenAIMessage> => {
  try {
    const parts = model.split("/");
    const api = parts[0] as keyof typeof apiUrls;
    const modelName = parts.slice(1).join("/");

    const res = await client.post(
      api,
      "/chat/completions",
      {
        model: modelName,
        messages,
        temperature: options?.temperature || 0,
        max_tokens: options?.maxTokens,
        tools: options?.tools,
        tool_choice: options?.toolChoice,
      },
    );

    if (res.status !== 200) {
      throw new Error(
        `OpenAI API error: ${res.statusText} ${JSON.stringify(res.data)}`,
      );
    }

    return res.data.choices[0].message;
  } catch (error) {
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};

export const embedding = async (text: string) => {
  const embeddingRes = await client.post(
    "openai",
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

  const transcriptionRes = await fetch(
    `${apiUrls.openai.url}/audio/transcriptions`,
    {
      method: "POST",
      body: formData,
      headers: {
        "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
    },
  ).then((r) => r.json());

  console.log(
    `Transcription response: ${JSON.stringify(transcriptionRes)}`,
  );

  return transcriptionRes.text;
};

export const generateImage = async (
  prompt: string,
  size?: string,
  style?: "vivid" | "natural",
): Promise<ArrayBuffer> => {
  const res = await client.post(
    "openai",
    "images/generations",
    {
      prompt,
      model: "dall-e-3",
      size: size ?? "1024x1024",
      style,
    },
  );

  console.log(`Image generation response: ${JSON.stringify(res.data)}`);

  const url = res.data.data[0].url;

  const imageRes = await fetch(url).then((r) => r.arrayBuffer());

  return imageRes;
};

export const visualizeImage = async (
  model: string,
  image_url: string,
  prompt: string,
  options?: RawMessageOptions,
): Promise<string> => {
  try {
    const parts = model.split("/");
    const api = parts[0] as keyof typeof apiUrls;
    const modelName = parts.slice(1).join("/");

    const res = await client.post(
      api,
      modelName,
      {
        image_url,
        prompt,
        temperature: options?.temperature || 0.2,
        max_tokens: options?.maxTokens,
      },
      {
        headers: {
          Authorization: `Key ${Deno.env.get(apiUrls[api].keyEnv)}`,
        },
      },
    );

    if (res.status !== 200) {
      throw new Error(
        `Vision API error: ${res.statusText} ${JSON.stringify(res.data)}`,
      );
    }

    return res.data.output;
  } catch (error) {
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};
