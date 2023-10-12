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
  activeCampaignApiKey: getOrThrow('ACTIVE_CAMPAIGN_API_KEY'),
  activeCampaignBaseUrl: getOrThrow('ACTIVE_CAMPAIGN_BASE_URL'),
  activeCampaignTag: process.env['ACTIVE_CAMPAIGN_TAG'] || '',
  onboardingEventId: process.env['ONBOARDING_EVENT_ID'] || ''
};