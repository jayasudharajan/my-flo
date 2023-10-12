import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import 'source-map-support/register';
import config from './config';
import DynamoDbClient from './DynamoDbClient';
import DbHelper from './DbHelper';
import { OnboardingLog } from './interfaces';
import moment from 'moment-timezone';
import axios from 'axios';
import _ from 'lodash';
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);

type DeviceTimezone = {
  deviceId: string,
  timezone: string
};

async function ensureFirstInstallEvent(record: any): Promise<OnboardingLog | null> {
  const onboardingEvent = record as OnboardingLog;
  const isFirstInstalledEvent = await dbHelper.isFirstInstalledEvent(onboardingEvent);

  if (!isFirstInstalledEvent) {
    console.log('Duplicate install event. Skipping.');
    return null;
  }

  return onboardingEvent;
}

async function getDeviceTimezone(icdId: string): Promise<DeviceTimezone | null> {
  const device = await dbHelper.getDeviceRecord(icdId);

  if (device === null) {
    console.log('No device found. Skipping.');
    return null;
  }

  const location = await dbHelper.getLocationByLocationId(device.location_id);

  if (!location || !location.timezone) {
    console.log('No timezone defined. Skipping.');
    return null;
  }

  return {
    deviceId: device.device_id,
    timezone: location.timezone
  };
}

async function deployHealthTestTimes(deviceId: string, times: number[]) {
  const now = new Date().toISOString();
  const data = {
    compute_time: now,
    reference_time: {
      timezone: 'Etc/UTC',
      data_start_date: now
    },
    times
  };
  const request = {
    method: 'POST',
    url: `${ config.apiUrl }/${ deviceId }`,
    headers: {
      'Content-Type': 'application/json',
      Authorization: config.apiToken
    },
    data
  };

  console.log(
    'Sending ', 
    JSON.stringify({ url: request.url, data }, null, 4)
  );

  return axios(request);
}

function calculateHealthTestTimes(timezone: string): number[] {
  const localTimesInMinsAfterUtcMidnight = config.defaultHealthTestTimes
    .map((time: string) => {
      const utcDateTime = moment.tz(time, 'HH:mm', timezone).toISOString();
      const utcMidnight = moment(utcDateTime).utc().startOf('day').toISOString();

      return Math.abs(
        moment(utcDateTime).diff(utcMidnight, 'minutes')
      );
    });

   return localTimesInMinsAfterUtcMidnight;
}

export const deployDefaultHealthTestTimes: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  try { 
    const newRecords = event.Records.map(record => {
      const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};
      return DynamoDB.Converter.unmarshall(newImageOrEmpty);
    })
    .filter(record => !_.isEmpty(record));
    
    await Promise.all(
      newRecords
        .map(async (record) => {
          const onboardingEvent = await ensureFirstInstallEvent(record);
          const deviceTimezone = onboardingEvent && await getDeviceTimezone(onboardingEvent.icd_id);

          if (deviceTimezone === null) {
            return null;
          }

          const times = calculateHealthTestTimes(deviceTimezone.timezone);

          return deployHealthTestTimes(deviceTimezone.deviceId, times);
        })
    );

    done();
  } catch (err) {
    console.log(err);
    done(err);
  }
}
