import { supabase } from "../_shared/supabase.ts";
import jobs from "./jobs/index.ts";

export async function createJob<Name extends keyof typeof jobs>(
  name: Name,
  data: Parameters<typeof jobs[Name]>[0]["data"],
) {
  const { error } = await supabase.from("job").insert({ name, data });
  if (error) {
    console.error("Error creating job:", error.message);
    throw error;
  }
}
