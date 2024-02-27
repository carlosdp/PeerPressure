const db = await Deno.openKv();

db.listenQueue(({ queue, data }) => {
  console.log(`Received from queue ${queue}:`, data);
});

export const handler: Deno.ServeHandler = async (req) => {
  await db.enqueue({ queue: "chat", data: { message: "hello world" } });

  const { name } = await req.json();
  const data = {
    message: `Hello ${name}!`,
  };

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  );
};
