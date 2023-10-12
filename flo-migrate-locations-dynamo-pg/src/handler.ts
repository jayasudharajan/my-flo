import 'source-map-support/register';
import { Callback, Context, DynamoDBStreamEvent, DynamoDBRecord, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import _ from 'lodash';
import { morphism } from 'morphism';
import squel from 'squel';
import pg from 'pg';
import {
  DynamoLocation,
  PostgresLocation,
  DynamoToPgLocationSchema,
  DynamoToPgUserLocationSchema,
  DynamoUserLocationRole,
  PostgresUserLocation,
  jsonColumns
} from './model';
import config from './config';
import * as uuid from 'uuid';

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

    const { location, userLocation } = parseRecords(event);

    console.log(JSON.stringify({
      location,
      userLocation
    }, null, 4));

    await Promise.all([
      ...location.upsert.map(record => pgUpsertLocation(pgClient, record)),
      ...location.remove.map(id => pgDeleteLocation(pgClient, id)),
      ...userLocation.upsert.map(record => pgUpsertUserLocation(pgClient, record)),
      ...userLocation.remove.map(ids => pgDeleteUserLocation(pgClient, ids))
    ]);

    await pgClient.end();

    done();
  } catch (err) {
    console.log(err);
    await pgClient.end();
    done(err);
  }

};

function parseRecords(event: DynamoDBStreamEvent) {
  const locationRecords = event.Records
    .filter(record =>
      record.dynamodb &&
      record.dynamodb.Keys &&
      record.dynamodb.Keys.location_id &&
      record.dynamodb.Keys.account_id &&
      record.dynamodb.Keys.location_id.S !== 'undefined' &&
      record.dynamodb.Keys.account_id.S !== 'undefined' &&
      uuid.validate(record.dynamodb.Keys.account_id.S ?? '')
    );
  const userLocationRecords = event.Records
    .filter(record =>
      record.dynamodb &&
      record.dynamodb.Keys &&
      record.dynamodb.Keys.user_id &&
      record.dynamodb.Keys.location_id &&
      record.dynamodb.Keys.user_id.S !== 'undefined' &&
      record.dynamodb.Keys.location_id.S !== 'undefined'
  );

  return {
    location: parseLocationRecords(locationRecords),
    userLocation: parseUserLocationRecords(userLocationRecords)
  };
}

function parseLocationRecords(records: DynamoDBRecord[]): { upsert: PostgresLocation[], remove: string[] } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoLocation | undefined;

      return data && morphism(DynamoToPgLocationSchema, data);
    })
    .filter(record =>
      record &&
      (
        (!_.isEmpty(record.location_class) && record.location_class !== 'unit') ||
        record.nickname ||
        record.address ||
        record.city ||
        record.is_profile_complete
      )
    ) as PostgresLocation[];

  const deleteIds = records
    .filter(record => record.eventName === 'REMOVE')
    .map(record => {
      const image = record.dynamodb && record.dynamodb.OldImage;
      const data = image && DynamoDB.Converter.unmarshall(image);

      return data && data.location_id;
    })
    .filter(_.identity);

  return {
    upsert: upsertRecords,
    remove: deleteIds
  };
}

function parseUserLocationRecords(records: DynamoDBRecord[]): { upsert: PostgresUserLocation[], remove: Array<{ user_id: string, location_id: string }> } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoUserLocationRole | undefined;

      return data && morphism(DynamoToPgUserLocationSchema, data);
    })
    .filter(_.identity) as PostgresUserLocation[];

  const deleteIds = records
    .filter(record => record.eventName === 'REMOVE')
    .map(record => {
      const image = record.dynamodb && record.dynamodb.OldImage;
      const data = image && DynamoDB.Converter.unmarshall(image);

      return data && {
        location_id: data.location_id as string,
        user_id: data.user_id as string
      };
    })
    .filter(_.identity) as Array<{ user_id: string, location_id: string }>;

  return {
    upsert: upsertRecords,
    remove: deleteIds
  };
}

async function pgUpsertLocation(pgClient: pg.Pool, location: PostgresLocation): Promise<void> {
 const pgRecord = _.mapValues(
   location,
   (value, column) =>
     value !== undefined && value !== null && jsonColumns.indexOf(column) >= 0 ?
       JSON.stringify(value) :
       (_.isString(value) && _.isEmpty(value.trim())) || value === undefined ?
         null :
         value
 );
 const queryBuilder = squel.useFlavour('postgres')
    .insert()
    .into('"location"');

  _.forEach(pgRecord, (value, column) => {
    // DEBUG:
    // tslint:disable
    if (column === 'is_profile_complete') {
      console.log({ value, column, set: (_.isEmpty(value) && value !== false) ? null : value });
    }
    queryBuilder.set(`"${ column }"`, (_.isEmpty(value) && !_.isBoolean(value)) ? null : value)
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

async function pgUpsertUserLocation(pgClient: pg.Pool, userLocation: PostgresUserLocation): Promise<void> {
 const pgRecord = _.mapValues(
   userLocation,
   (value, column) =>
     value !== undefined && value !== null && jsonColumns.indexOf(column) >= 0 ?
       JSON.stringify(value) :
       (_.isString(value) && _.isEmpty(value.trim())) || value === undefined ?
         null :
         value
 );
 const queryBuilder = squel.useFlavour('postgres')
    .insert()
    .into('"user_location"');

  _.forEach(pgRecord, (value, column) => {
    queryBuilder.set(`"${ column }"`, (_.isEmpty(value) && !_.isBoolean(value)) ? null : value)
  });

  const {
    user_id,
    location_id,
    ...cols
  } = pgRecord;

  queryBuilder.onConflict('"user_id", "location_id"', _.mapKeys(cols, (_value, key) => `"${ key }"`));

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

async function pgDeleteLocation(pgClient: pg.Pool, id: string): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"location"')
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

async function pgDeleteUserLocation(pgClient: pg.Pool, ids: { user_id: string, location_id: string }): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"user_location"')
    .where('"user_id" = ?', ids.user_id)
    .where('"location_id" = ?', ids.location_id)
    .toParam();

  // DEBUG:
  // tslint:disable
  console.log('DELETING');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('DELETED');
  console.log(ids);
}
