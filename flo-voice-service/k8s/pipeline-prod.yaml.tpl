image:
  tag: "$CI_PIPELINE_ID"
secrets:
  datas:
    application_name: "${APPLICATION_NAME_PROD}"
    environment: production
    kafka_group_id: "${KAFKA_GROUP_ID_PROD}"
    kafka_host: "${KAFKA_HOST_PROD}"
    kafka_voice_topic: "${KAFKA_VOICE_TOPIC_PROD}"
    kill_switch_enabled: "${KILL_SWITCH_ENABLED_PROD}"
    new_relic_api_key: "${NEW_RELIC_API_KEY_PROD}"
    new_relic_app_name: "${NEW_RELIC_APP_NAME_PROD}"
    new_relic_license_key: "${NEW_RELIC_LICENSE_KEY_PROD}"
    new_relic_log: "${NEW_RELIC_LOG_PROD}"
    service_command: "${SERVICE_COMMAND_PROD}"
    twilio_auth_token: "${TWILIO_AUTH_TOKEN_PROD}"
    twilio_number: "${TWILIO_NUMBER_PROD}"
    twilio_sid: "${TWILIO_SID_PROD}"
