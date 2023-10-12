import _ from 'lodash';
import DynamoDbClient from './DynamoDbClient';
import { Account, Icd, Location, OnboardingEvent, OnboardingLog, User, UserInfo, UserDetails, PushNotificationToken } from './interfaces';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async retrieveOwnerUserInfo(icdId: string): Promise<UserInfo | null> {
    try {
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

      const [user, userDetail, pushNotificationTokens] = await Promise.all([
        this.dynamoDbClient.get<User>('User', { id: account.owner_user_id }),
        this.dynamoDbClient.get<UserDetails>('UserDetail', { user_id: account.owner_user_id }),
        this.getPushNotificationTokensByUserId(account.owner_user_id),
      ]);

      if (user === null) {
        console.log(`User with ID ${account.owner_user_id} not found for ICD ${icdId}`);
        return null;
      }

      if (_.isEmpty(pushNotificationTokens)) {
        console.log(`Not found any Push Notification Token with User ID ${account.owner_user_id} for ICD ${icdId}`);
        return null;
      }

      return {
        email: user.email,
        firstName: (userDetail || {} as UserDetails).firstname,
        lastName: (userDetail || {} as UserDetails).lastname,
        pushNotificationTokens: _.uniqBy(pushNotificationTokens, 'aws_endpoint_id') || [] as PushNotificationToken[],
        userId: account.owner_user_id,
      };
    } catch (err) {
      console.log('An error ocurred trying to retrieve onwer user info', err);
      return null;
    }
  }

  private async getPushNotificationTokensByUserId(userId: string): Promise<PushNotificationToken[] | undefined> {
    const pushNotificatoinTokens = await this.dynamoDbClient.query<PushNotificationToken>('PushNotificationToken', {
      IndexName: 'UserIdMobileIdClientIdIndex',
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': userId
      }
    })
    return pushNotificatoinTokens && pushNotificatoinTokens.filter(item => item.aws_endpoint_id && item.is_disabled !== 1);
  }

  public isOutOfLearningEvent(log: OnboardingLog): boolean {
    return log.event === OnboardingEvent.SYSTEM_MODE_UNLOCKED;
  }
}

export default DbHelper;