import _ from 'lodash';

const getOrThrow = (variableName: string): string => {
  const value = process.env[variableName];

  if (_.isNil(value)) {
    throw new Error(`${variableName} is not set.`);
  }
  return value;
}

export default {
  sendWithUsBaseUrl: getOrThrow('SEND_WITH_US_BASE_URL'),
  sendWithUsApiKey: getOrThrow('SEND_WITH_US_API_KEY'),
  s3Bucket: getOrThrow('S3_BUCKET')
}