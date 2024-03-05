export type Photo = {
  key: string;
  description?: string | null;
};

export type Block = { photo: { key: string } } | { gas: { text: string } };
