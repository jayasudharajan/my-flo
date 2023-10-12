image:
  tag: "$CI_PIPELINE_ID"
secrets:
  datas:
    application_name: "${APPLICATION_NAME_DEV}"
    environment: dev
    kafka_group_id: "${KAFKA_GROUP_ID_DEV}"
    kafka_host: "${KAFKA_HOST_DEV}"
    kafka_voice_topic: "${KAFKA_VOICE_TOPIC_DEV}"
    kill_switch_enabled: "${KILL_SWITCH_ENABLED_DEV}"
    service_command: "${SERVICE_COMMAND_DEV}"
    twilio_auth_token: "${TWILIO_AUTH_TOKEN_DEV}"
    twilio_number: "${TWILIO_NUMBER_DEV}"
    twilio_sid: "${TWILIO_SID_DEV}"
