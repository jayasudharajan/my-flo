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
  deviceStateServiceBaseUrl: getOrThrow('DEVICE_STATE_SERVICE_BASE_URL'),
  fireWriterServiceBaseUrl: getOrThrow('FIRE_WRITER_SERVICE_BASE_URL')
};
