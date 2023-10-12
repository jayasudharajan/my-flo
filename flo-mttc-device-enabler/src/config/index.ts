import _ from 'lodash';

const getOrThrow = (variableName: string): string => {
  const value = process.env[variableName];

  if (_.isNil(value)) {
    throw new Error(`${variableName} is not set.`);
  }
  return value;
}

export default {
  tablePrefix: getOrThrow('TABLE_PREFIX'),
  kafkaBrokerList: getOrThrow('KAFKA_BROKER_LIST'),
  kafkaTopic: getOrThrow('KAFKA_TOPIC'),
  kafkaTimeout: getOrThrow('KAFKA_TIMEOUT'),
  kafkaConnectTimeout: getOrThrow('KAFKA_CONNECT_TIMEOUT'),
  kafkaSocketTimeout: getOrThrow('KAFKA_SOCKET_TIMEOUT'),
  mttcMinDays: getOrThrow('MTTC_MIN_DAYS'),
  apiV1BaseUrl: getOrThrow('API_V1_BASE_URL'),
  apiV2BaseUrl: getOrThrow('API_V2_BASE_URL'),
  apiAccessToken: getOrThrow('API_ACCESS_TOKEN'),
  apiV1DevicesPath: getOrThrow('API_V1_DEVICES_PATH'),
  apiV2DevicesPath: getOrThrow('API_V2_DEVICES_PATH'),
  deviceScrollTtl: getOrThrow('DEVICE_SCROLL_TTL'),
  deviceScrollSize: getOrThrow('DEVICE_SCROLL_SIZE'),
  minFirmwareVersion: getOrThrow('MIN_FIRMWARE_VERSION'),
  ignoreMttcOverride: getOrThrow('IGNORE_MTTC_OVERRIDE') === 'true'
};
