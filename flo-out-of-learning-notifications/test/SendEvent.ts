import sendEventToPinpoint from '../index';
import { OnboardingLog } from '../interfaces';

const log: OnboardingLog = {
  created_at: "2019-05-17T14:12:24.377Z",
  event: 3,
  icd_id: "ef2f7c84-c137-4659-af38-4b706f8f7bf2"
};

sendEventToPinpoint(log)
  .then(() => console.log('Onboarding event successfully processed'))
  .catch((err: any) => console.error(err));