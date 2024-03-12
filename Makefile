types:
	@supabase gen types typescript --local | tee supabase/functions/_shared/supabaseTypes.d.ts > /dev/null

test-profile:
	deno run --allow-read --allow-write --allow-env --allow-net scripts/testProfileBuild.ts

server:
	@supabase functions serve

worker:
	@export SUPABASE_URL="http://localhost:54321" && \
	export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0" && \
	export SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" && \
	deno run --watch --allow-read --allow-env --env=./supabase/functions/.env --allow-net supabase/functions/worker/worker.ts
