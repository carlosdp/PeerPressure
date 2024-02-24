import axios from 'axios';
import axiosRetry from 'axios-retry';

const client = axios.create({ baseURL: 'https://api.openai.com/v1' });
axiosRetry(client, {
  retries: 5,
  retryDelay: axiosRetry.exponentialDelay,
  retryCondition: error =>
    axiosRetry.isNetworkOrIdempotentRequestError(error) ||
    error.response?.status === 429 ||
    error.response?.status === 500 ||
    error.response?.status === 502,
});

export const message = async (model, messages, maxTokens, temperature) => {
  const data = {
    model,
    messages,
    temperature: temperature || 0,
    max_tokens: maxTokens,
  };
  try {
    const res = await client.post('/chat/completions', data, {
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      },
    });

    if (res.status !== 200) {
      throw new Error(`OpenAI API error: ${res.statusText}`);
    }

    return res.data.choices[0].message.content.trim();
  } catch (error) {
    // @ts-ignore
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};

export const rawMessage = async (
  model,
  messages,
  options
) => {
  try {
    const res = await client.post(
      '/chat/completions',
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
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        },
      }
    );

    if (res.status !== 200) {
      throw new Error(`OpenAI API error: ${res.statusText}`);
    }

    return res.data.choices[0].message;
  } catch (error) {
    // @ts-ignore
    console.error(JSON.stringify(error.response?.data));
    throw error;
  }
};

export const embedding = async (text) => {
  const embeddingRes = await client.post(
    '/embeddings',
    {
      model: 'text-embedding-ada-002',
      input: [text],
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      },
    }
  );

  return embeddingRes.data.data[0].embedding;
};

export const transcribe = async (audio) => {
  const formData = new FormData();
  formData.append('file', audio);
  formData.append('model', 'whisper-1');
  formData.append('language', 'en');
  formData.append('response_format', 'json');
  formData.append('temperature', '0');

  const transcriptionRes = await client.post('/audio/transcriptions', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
      Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
    },
  });

  return transcriptionRes.data.text;
};

export const generateImage = async (
  prompt,
  size,
  style
) => {
  const res = await client.post(
    'https://api.openai.com/v1/images/generations',
    {
      prompt,
      model: 'dall-e-3',
      size: size ?? '1024x1024',
      style,
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      },
    }
  );

  const url = res.data.data[0].url;

  const imageRes = await axios.get(url, { responseType: 'arraybuffer' });

  return imageRes.data;
};
