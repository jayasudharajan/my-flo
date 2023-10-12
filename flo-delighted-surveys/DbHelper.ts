import _ from 'lodash';
import moment from 'moment';
import DynamoDbClient from './DynamoDbClient';
import { Account, AccountSubscription, Icd, Location, OnboardingEvent, OnboardingLog, User, UserDetails, UserInfo } from './interfaces';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async retrieveOwnerUserInfoByAccountId(accountId: string): Promise<UserInfo | null> {
    const account = await this.dynamoDbClient.get<Account>('Account', { id: accountId });

    if (account === null) {
      console.log(`Account with ID ${accountId} not found.`);
      return null;
    }
    return this.retrieveOwnerUserInfo(account.owner_user_id, account.id);
  }

  public async retrieveOwnerUserInfoByIcdId(icdId: string): Promise<UserInfo | null> {
    const icd = await this.dynamoDbClient.get<Icd>('ICD', { id: icdId });

    if (icd === null) {
      console.log(`ICD with ID ${icdId} not found`);
      return null;
    }

    const location = _.first(await this.dynamoDbClient.query<Location>('Location', {
      IndexName: 'LocationIdIndex',
      KeyConditionExpression: 'location_id = :location_id',
      ExpressionAttributeValues: {
        ':location_id': icd.location_id
      }
    }));

    if (!location) {
      console.log(`Location with ID ${icd.location_id} not found for ICD ${icdId}`);
      return null;
    }

    const account = await this.dynamoDbClient.get<Account>('Account', { id: location.account_id });

    if (account === null) {
      console.log(`Account with ID ${location.account_id} not found for ICD ${icdId}`);
      return null;
    }

    return this.retrieveOwnerUserInfo(account.owner_user_id, account.id);
  }

  public async isFirstInstalledEvent(log: OnboardingLog): Promise<boolean> {
    return Promise.resolve(
      log.event >= OnboardingEvent.INSTALLED &&
        this.noPreviousInstalledEvent(log.icd_id, log.created_at)
    );
  }

  private async retrieveOwnerUserInfo(ownerUserId: string, accountId: string): Promise<UserInfo | null> {
    const [user, userDetail, subscription] = await Promise.all([
      this.dynamoDbClient.get<User>('User', { id: ownerUserId }),
      this.dynamoDbClient.get<UserDetails>('UserDetail', { user_id: ownerUserId }),
      this.dynamoDbClient.get<AccountSubscription>('AccountSubscription', { account_id: accountId })
    ]);

    if (user === null) {
      console.log(`User with ID ${ownerUserId} not found.`);
      return null;
    }

    return {
      email: user.email,
      firstName: (userDetail || {} as UserDetails).firstname,
      lastName: (userDetail || {} as UserDetails).lastname,
      isFloProtectSubscriber: !_.isNil(subscription) && this.isFloProtectSubscriber(subscription)
    };
  }

  private async noPreviousInstalledEvent(icdId: string, installedEventDate: string): Promise<boolean> {
    const logs = await this.dynamoDbClient.query<OnboardingLog>('OnboardingLog', {
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': icdId
      }
    });

    return _.isEmpty(_.find(logs, (log) =>
      log.event >= OnboardingEvent.INSTALLED &&
        moment(log.created_at).isBefore(moment(installedEventDate))
    ));
  }

  private isFloProtectSubscriber(subscription: AccountSubscription): boolean {
    return _.isNil(subscription.canceled_at) && _.isNil(subscription.ended_at);
  }
}

export default DbHelper;