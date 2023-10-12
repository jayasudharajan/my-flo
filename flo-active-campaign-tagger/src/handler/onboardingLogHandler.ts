import _ from 'lodash';
import { updateTagsInActiveCampaign } from '../active-campaign/activeCampaignTagger';
import config from '../config';
import { OnboardingLog, RecordImage } from '../interfaces';
import dbHelper from '../database/DbHelper';

const isExpectedEvent = (onboardingLog: OnboardingLog): boolean => {
  return onboardingLog.event == parseInt(config.onboardingEventId);
}

export const handleOnboardingLog = async (onboardingLog: RecordImage<OnboardingLog>): Promise<void> => {
  const newOnboardingLog = onboardingLog.new;

  if (!isExpectedEvent(newOnboardingLog)) {
    return Promise.resolve();
  }

  console.log(`Retrieving all users associated with Device ICD ${newOnboardingLog.icd_id}.`);
  const users = await dbHelper.retrieveAllUsersAssociatedWithDevice(newOnboardingLog.icd_id);
  console.log(`Retrieved users associated with Device ICD ${newOnboardingLog.icd_id}: ${JSON.stringify(_.map(users, 'email'))}`);

  if (_.isEmpty(users)) {
    console.warn(`No users associated with Device ICD ${newOnboardingLog.icd_id}`);
    return Promise.resolve();
  }

  await Promise.all(users.map(user => updateTagsInActiveCampaign(user, config.activeCampaignTag)));
}