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
  dataScienceApiUrl: getOrThrow('DATA_SCIENCE_API_URL'),
  dataScienceApiKey: getOrThrow('DATA_SCIENCE_API_KEY')
};
