import { createSupabaseClient } from "../_shared/supabase.ts";
import { createJob } from "../worker/job.ts";

export const handler: Deno.ServeHandler = async (req) => {
  const { matchId, message } = await req.json();

  const supabase = createSupabaseClient(req.headers.get("Authorization")!);

  const { error } = await supabase.auth.getUser();
  if (error) {
    console.log("Error getting user:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: profile, error: profileError } = await supabase.rpc(
    "get_profile",
  );
  if (profileError) {
    console.error("Error getting profile:", profileError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const { error: messageError } = await supabase.from("messages").insert({
    match_id: matchId,
    sender_id: profile.id,
    message,
  });
  if (messageError) {
    console.error("Error inserting message:", messageError.message);
    return new Response(
      JSON.stringify({ error: "Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  await createJob("sendBotMessage", { matchId });

  return new Response(
    JSON.stringify({ success: true }),
    { headers: { "Content-Type": "application/json" } },
  );
};
