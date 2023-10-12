import { DynamoDB } from 'aws-sdk';
import config from '../config';
import DbHelper from '../database/DbHelper';
import DynamoDbClient from '../database/dynamo/DynamoDbClient';
import { OnboardingEvent, OnboardingLog, PushNotificationToken } from '../interfaces';
import { sendEventToPinpoint } from '../pinpoint/pinpointSender';

const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);

const isInstalledEvent = (onboardingLog: OnboardingLog): boolean => {
  return onboardingLog.event === OnboardingEvent.INSTALLED
}

export const handleOnboardingLog = async (onboardingLog: OnboardingLog): Promise<void> => {
  if (!isInstalledEvent(onboardingLog)) {
    return Promise.resolve();
  }

  console.log(`Retrieving owner user info for Device ICD ${onboardingLog.icd_id}.`);
  const ownerUserInfo = await dbHelper.retrieveOwnerUserInfo(onboardingLog.icd_id);

  if (ownerUserInfo === null) {
    return Promise.resolve();
  }

  console.log(`Sending ${ownerUserInfo.pushNotificationTokens.length} events to Pinpoint for user: ${ownerUserInfo.email}`);
  await Promise.all(ownerUserInfo.pushNotificationTokens.map((item: PushNotificationToken) =>
    sendEventToPinpoint({
      email: ownerUserInfo.email,
      firstName: ownerUserInfo.firstName,
      lastName: ownerUserInfo.lastName,
      userId: ownerUserInfo.userId,
      device: ownerUserInfo.device,
      clientType: item.client_type,
      token: item.token,
      awsEndpointId: item.aws_endpoint_id,
      createdAt: onboardingLog.created_at
    })
  ));
  console.log(`Successfully sent ${ownerUserInfo.pushNotificationTokens.length} events to Pinpoint for user ${ownerUserInfo.email}.`);
}
