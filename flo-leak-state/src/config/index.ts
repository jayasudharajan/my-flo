import _ from 'lodash';

const getOrThrow = (variableName: string): string => {
  const value = process.env[variableName];

  if (_.isNil(value)) {
    console.error(`${variableName} is not set.`);
    throw new Error(`${variableName} is not set.`);
  }
  return value;
}

export default {
  apiUrl: getOrThrow('API_URL'),
  apiToken: getOrThrow('API_TOKEN'),
  reportStateEndpoint: getOrThrow('REPORT_STATE_ENDPOINT'),
  kafkaBrokerList: getOrThrow('KAFKA_BROKER_LIST'),
  kafkaTopic: getOrThrow('KAFKA_TOPIC'),
  kafkaGroupId: getOrThrow('KAFKA_GROUP_ID'),
  kafkaConnectionTimeoutInMs: parseInt(getOrThrow('KAFKA_CONNECTION_TIMEOUT_IN_MS')),
  numberOfMessagesToConsume: parseInt(getOrThrow('NUMBER_OF_MESSAGES_TO_CONSUME_AT_ONCE')),
  maxExecutionTimeInSeconds: parseInt(getOrThrow('MAX_EXECUTION_TIME_IN_SECONDS')),
  leakRelatedAlarmIds: new Set(getOrThrow('LEAK_RELATED_ALARM_IDS').split(',').map(alarmId => parseInt(alarmId))),
  reportStateFunctionName: getOrThrow('REPORT_STATE_FUNCTION_NAME'),
  topicEmptyCheckLoopIntervalInMs: parseInt(getOrThrow('TOPIC_EMPTY_CHECK_LOOP_INTERVAL_IN_MS')),
  iftttAlertEndpoint: getOrThrow('IFTTT_ALERT_ENDPOINT'),
  iftttAlertFunctionName: getOrThrow('IFTTT_ALERT_FUNCTION_NAME')
};