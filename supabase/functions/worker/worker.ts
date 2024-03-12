import { boss } from "./db.ts";
import logger from "../logger.ts";
import jobs from "./jobs/index.ts";

logger.info("Worker booting up...");

boss.start();

Deno.addSignalListener("SIGINT", async () => {
  logger.info("SIGINT received, stopping...");
  await boss.stop();
  Deno.exit();
});

Deno.addSignalListener("SIGTERM", async () => {
  logger.info("SIGTERM received, stopping...");
  await boss.stop();
  Deno.exit();
});

// eslint-disable-next-line @typescript-eslint/ban-types
const wrapExceptionLog = (jobFunction: Function) => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return async (...args: any[]) => {
    try {
      return await jobFunction(...args);
    } catch (error) {
      const exception = error as Error;
      logger.error(`${exception.message}\n${exception.stack}`);
      throw error;
    }
  };
};

for (const [jobName, jobFunction] of Object.entries(jobs)) {
  boss.work(jobName, wrapExceptionLog(jobFunction));
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  boss.onComplete(jobName, (job: { failed: boolean; response: any }) => {
    logger.debug(job);
    if (job.failed) {
      logger.error(`Job ${jobName} failed: ${job.response}`);
    }
  });
}

boss.on("error", (error) => logger.error(error));

// Crons
boss.schedule("matchBots", "* * * * *");

logger.info("Worker running!");
