export default {
  tablePrefix: process.env.TABLE_PREFIX,
  apiUrl: process.env.API_URL,
  apiToken:  process.env.API_TOKEN,
  defaultHealthTestTimes: JSON.parse(process.env.DEFAULT_HEALTH_TEST_TIMES || '[]')
};