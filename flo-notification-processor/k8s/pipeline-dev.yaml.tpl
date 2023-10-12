image:
  tag: "${CI_PIPELINE_ID}"
secrets:
  datas:
    APPLICATION_NAME: "notification-processor"
    ENVIRONMENT: "development"
    FLO_HTTP_PORT: "${FLO_HTTP_PORT}"
    FLO_KAFKA_CN: "${FLO_KAFKA_CN}"
    FLO_KAFKA_GROUP_ID: "${FLO_KAFKA_GROUP_ID}"
    FLO_PGDB_CN: "${FLO_PGDB_CN}"
    FLO_PRESENCE_HOST: "${FLO_PRESENCE_HOST}"
    FLO_REDIS_CN: "${FLO_REDIS_CN}"
    PG_PASS: "${PG_PASS_DEV}"
    PG_USER: "${PG_USER_DEV}"
    FLO_API_URL: "${FLO_API_URL}"
