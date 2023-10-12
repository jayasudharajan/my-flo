import 'source-map-support/register';
import { Callback, Context, DynamoDBStreamEvent, DynamoDBRecord, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import _ from 'lodash';
import { morphism } from 'morphism';
import squel from 'squel';
import pg from 'pg';
import {
  DynamoDevice, DynamoToPgDeviceSchema, PostgresDevice
} from './model';
import config from './config';

export const handle: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  // DEBUG:
  // tslint:disable
  console.log('BEGIN');
  console.log(JSON.stringify(event, null, 4));
  
  const pgClient = new pg.Pool({
    user: config.pgUser,
    password: config.pgPw,
    host: config.pgHost,
    database: config.pgDb,
    port: config.pgPort,
    connectionTimeoutMillis: 10000,
    query_timeout: 10000
  });

  try {
    // DEBUG:
    // tslint:disable
    console.log('PARSE');
 
    const { device } = parseRecords(event);

    console.log(JSON.stringify({
      device
    }, null, 4));

    // First REMOVE, and then UPSERT to avoid missing records on device transfer.
    await Promise.all(device.remove.map(id => pgDeleteDevice(pgClient, id)));
    await Promise.all(device.upsert.map(record => pgUpsertDevice(pgClient, record)));
  
    await pgClient.end();

    done();
  } catch (err) {
    console.log(err);
    await pgClient.end();
    done(err);
  }
};

function parseRecords(event: DynamoDBStreamEvent) {
  const deviceRecords = event.Records
    .filter(record =>
      record.dynamodb?.Keys?.id?.S !== undefined
    );

  return {
    device: parseDeviceRecords(deviceRecords),
  };
}

function parseDeviceRecords(records: DynamoDBRecord[]): { upsert: PostgresDevice[], remove: string[] } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoDevice | undefined;

      return data && morphism(DynamoToPgDeviceSchema, data);
    }) as PostgresDevice[];

  const deleteIds = records
    .filter(record => record.eventName === 'REMOVE')
    .map(record => {
      const image = record.dynamodb && record.dynamodb.OldImage;
      const data = image && DynamoDB.Converter.unmarshall(image);

      return data && data.id;
    })
    .filter(_.identity);
  
  return {
    upsert: upsertRecords,
    remove: deleteIds
  };
}

async function pgUpsertDevice(pgClient: pg.Pool, device: PostgresDevice): Promise<void> {
 const pgRecord = _.mapValues(
   device,
   (value) =>
       (_.isString(value) && _.isEmpty(value.trim())) || value === undefined ? 
         null :
         value
 );
 const queryBuilder = squel.useFlavour('postgres')
    .insert()
    .into('"device"');

  _.forEach(pgRecord, (value, column) => {
    queryBuilder.set(`"${ column }"`, value)
  });


  const {
    id,
    ...cols
  } = pgRecord;

  queryBuilder.onConflict('id', _.mapKeys(cols, (_value, key) => `"${ key }"`));

  const { text, values } = queryBuilder.toParam();

  // DEBUG:
  // tslint:disable
  console.log(JSON.stringify({ text, values }, null, 4));
  console.log('UPSERTING');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('UPSERTED');
  console.log(pgRecord);
}


async function pgDeleteDevice(pgClient: pg.Pool, id: string): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"device"')
    .where('"id" = ?', id)
    .toParam();

  // DEBUG:
  // tslint:disable
  console.log('DELETING');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('DELETED');
  console.log(id);
}
