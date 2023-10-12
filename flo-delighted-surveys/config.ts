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
  delightedApiBaseUrl: getOrThrow('DELIGHTED_API_BASE_URL'),
  delightedApiKey: getOrThrow('DELIGHTED_API_KEY'),
  surveyInitialDelay: getOrThrow('SURVEY_INITIAL_DELAY')
};