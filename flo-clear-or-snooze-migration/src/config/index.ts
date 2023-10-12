import _ from 'lodash';

const getOrThrow = (variableName: string): string => {
  const value = process.env[variableName];

  if (_.isNil(value)) {
    throw new Error(`${variableName} is not set.`);
  }
  return value;
}

export default {
  apiToken: getOrThrow('API_TOKEN'),
  gatewayUrl: getOrThrow('GATEWAY_URL'),
  tablePrefix: getOrThrow('TABLE_PREFIX'),
  awsRegion: getOrThrow('AWS_DEFAULT_REGION')
};
