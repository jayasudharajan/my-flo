import { DynamoDB } from 'aws-sdk';
import config from '../config';
import DbHelper from '../database/DbHelper';
import DynamoDbClient from '../database/dynamo/DynamoDbClient';
import { sendToDataScienceAPI } from '../dataScienceAPI/dataScienceAPISender';
import { OnboardingEvent, OnboardingLog } from '../interfaces';

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

  console.log(`Retrieving Device info with ID ${onboardingLog.icd_id}.`);
  const deviceInfo = await dbHelper.retrieveDeviceInfo(onboardingLog.icd_id);

  if (deviceInfo === null) {
    return Promise.resolve();
  }

  console.log(`Sending 'installed' status to Data Science API for Device ID ${onboardingLog.icd_id} / ${deviceInfo.device_id}.`);
  await sendToDataScienceAPI(deviceInfo.device_id, onboardingLog.created_at);
  console.log(`Successfully sent 'installed' status to Data Science API Service for Device ID ${onboardingLog.icd_id} / ${deviceInfo.device_id}.`);
}