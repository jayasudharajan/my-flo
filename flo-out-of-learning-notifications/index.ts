
import { DynamoDB, Pinpoint } from 'aws-sdk';
import { OnboardingLog, PushNotificationToken } from './interfaces';
import config from './config';
import DynamoDbClient from './DynamoDbClient';
import DbHelper from './DbHelper';
import PinpointApi from './PinpointApi';

const pinpointClient = new Pinpoint({ apiVersion: config.pinpointVersion });
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);
const pinpointApi = new PinpointApi(pinpointClient, config.pinpointAppId);

export default async function sendEventToPinpoint(log: OnboardingLog): Promise<void> {
  try {
    const isOutOfLearningEvent = await dbHelper.isOutOfLearningEvent(log);

    if (isOutOfLearningEvent) {
      const userData = await dbHelper.retrieveOwnerUserInfo(log.icd_id);
      if (userData) {
        await Promise.all(userData.pushNotificationTokens.map((item: PushNotificationToken) => {
          return pinpointApi.sendEvent({
            email: userData.email,
            firstName: userData.firstName,
            lastName: userData.lastName,
            userId: userData.userId,
            awsEndpointId: item.aws_endpoint_id,
            eventCreatedAt: log.created_at
          });
        }));
        return Promise.resolve();
      }
    }
  } catch(err) {
    console.error('Error sending event to Pinpoint', err);
  }
}