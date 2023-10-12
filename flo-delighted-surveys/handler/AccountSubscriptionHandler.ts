import moment from 'moment';
import DbHelper from '../DbHelper';
import { AccountSubscription, UserInfo } from '../interfaces';

class AccountSubscriptionEventHandler {
  constructor(
    private delighted: any,
    private dbHelper: DbHelper
  ) {}

  public async handle(accountSubscription: AccountSubscription): Promise<void> {
    const accountId = accountSubscription.account_id;
    const userInfo: UserInfo | null = await this.dbHelper.retrieveOwnerUserInfoByAccountId(accountId);

    if (userInfo === null) {
      console.warn(`Could not retrieve Owner User for Account ID ${accountId}`);
      return Promise.resolve();
    }

    return this.delighted.createPerson(userInfo, accountSubscription.created_at || moment.utc().toISOString());
  }
}

export default AccountSubscriptionEventHandler;