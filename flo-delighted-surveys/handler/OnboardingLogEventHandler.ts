import moment from 'moment';
import DbHelper from '../DbHelper';
import { OnboardingLog, UserInfo } from '../interfaces';

class OnboardingLogEventHandler {
  constructor(
    private delighted: any,
    private dbHelper: DbHelper
  ) {}

  public async handle(onboardingLog: OnboardingLog): Promise<void> {
    const isFirstInstalledEvent = await this.dbHelper.isFirstInstalledEvent(onboardingLog);
    if (!isFirstInstalledEvent) {
      return Promise.resolve();
    }

    const icdId = onboardingLog.icd_id;
    const userInfo: UserInfo | null = await this.dbHelper.retrieveOwnerUserInfoByIcdId(icdId);

    if (userInfo === null) {
      console.warn(`Could not retrieve Owner User for ICD ${icdId}`);
      Promise.resolve();
    }

    return this.delighted.createPerson(userInfo, onboardingLog.created_at || moment.utc().toISOString());
  }
}

export default OnboardingLogEventHandler;