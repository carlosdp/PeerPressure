import {
  ConnInfo,
  Handler,
  serve,
} from "https://deno.land/std@0.131.0/http/server.ts";
import { matchJob } from "./jobs.ts";

console.log("Setting up server function...");

const handlers = {
  "send-chat-message": await import("./send-chat-message/handler.ts").then((
    it,
  ) => ({ handler: it.handler, jobHandler: it.jobHandler })),
  "send-builder-message": await import("./send-builder-message/handler.ts")
    .then((
      it,
    ) => ({ handler: it.handler, jobHandler: it.jobHandler })),
} as Record<
  string,
  { handler: Handler; jobHandler: (data: any) => Promise<void> }
>;

const db = await Deno.openKv();
db.listenQueue(async ({ queue, ...data }) => {
  if (queue in handlers) {
    await handlers[queue].jobHandler(data);
  } else {
    console.error(`Unknown queue: ${queue}`);
  }
});

function localdevHandler(req: Request, connInfo: ConnInfo) {
  // CORS is needed if you're planning to invoke your function from a browser.
  if (req.method === "OPTIONS") {
    return new Response("OK");
  }
  console.log(`${req.method} ${req.url}`);
  const url = new URL(req.url);
  const urlParts = url.pathname.split("/");
  const handlerName = urlParts[urlParts.length - 1];
  const handler = handlers[handlerName].handler;
  try {
    return handler(req, connInfo);
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      },
    );
  }
}

Deno.cron("match-bots", "* * * * *", matchJob);

serve(localdevHandler);

console.log("OK");
