export default {
   pgUser: process.env.PG_USER,
   pgPw: process.env.PG_PW,
   pgHost: process.env.PG_HOST,
   pgDb: process.env.PG_DB,
   pgPort: process.env.PG_PORT ? parseInt(process.env.PG_PORT) : 5432
};