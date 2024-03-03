import PgBoss from "npm:pg-boss@9.0.3";

const DB_URL = "postgres://postgres:postgres@localhost:54322/postgres";

export const boss = new PgBoss({
  connectionString: DB_URL,
  schema: "public",
});
