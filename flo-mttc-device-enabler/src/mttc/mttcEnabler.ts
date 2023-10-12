import { DynamoDB } from 'aws-sdk';
import _ from 'lodash';
import moment from 'moment';
import Kafka from 'no-kafka';
import semver, { SemVer } from 'semver';
import uuid from 'uuid';
import retrieveFirmwareVersion from '../api-v2/retrieveFirmwareVersion';
import config from '../config';
import DbHelper from '../database/DbHelper';
import DynamoDbClient from '../database/dynamo/DynamoDbClient';
import { Device } from '../interfaces';

const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);

const enableMttc = async (kafkaProducer: Kafka.Producer, deviceId: string): Promise<void> => {
  const endDate = moment().toISOString();
  const startDate = moment(endDate).subtract(config.mttcMinDays, 'days').toISOString();
  const message = {
    device_id: deviceId,
    request_id: uuid.v4(),
    start_date: startDate,
    end_date: endDate
  };

  try {
    console.log(`Sending message to Kafka '${config.kafkaTopic}' Topic for Device ID ${deviceId}.`);
    const response = await kafkaProducer.send({
      topic: config.kafkaTopic,
      message: {
        value: JSON.stringify(message)
      }
    });
    console.log(`Successfully sent message to Kafka. Message = ${JSON.stringify(message)}, Response = ${JSON.stringify(response)}`);
  } catch (err) {
    console.error(`Error while sending message to Kafka. Message = ${JSON.stringify(message)}. Error = ${JSON.stringify(err)}`);
  }
}

const getSafeFirmwareVersion = (firmwareVersion?: string | null): SemVer | null | undefined => {
  try {
    if (_.isNil(firmwareVersion)) {
      return firmwareVersion;
    }
    return semver.coerce(firmwareVersion);
  } catch (err) {
    console.warn(`Error parsing Firmware version => ${firmwareVersion}. Error = ${err}`);
    return null;
  }
}

export const enableMttcForDevices = async (kafkaProducer: Kafka.Producer, devices: Device[]): Promise<void> => {
  await Promise.all(devices.map(async device => {
    if (!config.ignoreMttcOverride) {
      console.log(`Retrieving Admin MTTC override for Device ${device.id} / ${device.device_id}`);
      const isMttcOverridenByAdmin = await dbHelper.isMttcOverridenByAdmin(device.device_id);

      if (isMttcOverridenByAdmin) {
        console.log(`Device ${device.id} has MTTC overriden by admin. Skipping.`);
        return Promise.resolve();
      }

      console.log(`No admin MTTC override for Device ${device.id}.`)
    }

    console.log(`Retrieving Firmware Version for Device ${device.id}.`)
    const firmwareVersion = await retrieveFirmwareVersion(device.id);
    const safeFirmwareVersion = getSafeFirmwareVersion(firmwareVersion);

    console.log(`Retrieved Firmware Version for Device ${device.id} => ${safeFirmwareVersion}`)
    if (_.isNil(safeFirmwareVersion) || semver.lt(safeFirmwareVersion, config.minFirmwareVersion)) {
      console.log(`Device ${device.id} version ${safeFirmwareVersion} is less than required version ${config.minFirmwareVersion}. Skipping.`)
      return Promise.resolve();
    }

    return enableMttc(kafkaProducer, device.device_id);
  }));
}