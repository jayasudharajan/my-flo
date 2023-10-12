export default {
  apiUrl: process.env.API_URL,
  retryIntervalMs: parseInt(process.env.RETRY_INTERVAL_MS as string, 10),
  maxRetryCount: parseInt(process.env.MAX_RETRY_COUNT as string, 10),
};
