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
  pinpointAppId: getOrThrow('PINPOINT_APP_ID'),
  pinpointEventType: getOrThrow('PINPOINT_EVENT_TYPE'),
  pinpointAppTitle: getOrThrow('PINPOINT_APP_TITLE'),
  pinpointVersion: getOrThrow('PINPOINT_VERSION')
};
