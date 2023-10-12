import 'source-map-support/register';
import { Callback, Context, DynamoDBStreamEvent, DynamoDBRecord, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import _ from 'lodash';
import { morphism } from 'morphism';
import squel from 'squel';
import pg from 'pg';
import {
  DynamoAccount, DynamoToPgAccountSchema, DynamoToPgUserDetailSchema, DynamoToPgUserSchema, DynamoUser,
  DynamoUserDetail, jsonColumns, PostgresAccount, PostgresUser, PostgresUserDetail
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
 
    const { user, userDetail, account } = parseRecords(event);

    console.log(JSON.stringify({
      user,
      userDetail,
      account,
    }, null, 4));

    // First REMOVE, and then UPSERT to avoid missing records
    await Promise.all([
      ...user.remove.map(id => pgDeleteUser(pgClient, id)),
      ...userDetail.remove.map(userId => pgDeleteUserDetail(pgClient, userId)),
      ...account.remove.map(id => pgDeleteAccount(pgClient, id)),
    ]);
    await Promise.all([
      ...user.upsert.map(record => pgUpsertUser(pgClient, record)),
      ...userDetail.upsert.map(record => pgUpsertUserDetail(pgClient, record)),
      ...account.upsert.map(record => pgUpsertAccount(pgClient, record)),
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
  const userRecords = event.Records
    .filter(record =>
      record.dynamodb?.Keys?.id?.S !== undefined && record.eventSourceARN?.includes('User')
    );
  const userDetailRecords = event.Records
    .filter(record =>
      record.dynamodb?.Keys?.user_id?.S !== undefined
  );
  const accountRecords = event.Records
    .filter(record =>
      record.dynamodb?.Keys?.id?.S !== undefined && record.eventSourceARN?.includes('Account')
    );

  return {
    user: parseUserRecords(userRecords),
    userDetail: parseUserDetailsRecords(userDetailRecords),
    account: parseAccountRecords(accountRecords),
  };
}

function parseUserRecords(records: DynamoDBRecord[]): { upsert: PostgresUser[], remove: string[] } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoUser | undefined;

      return data && morphism(DynamoToPgUserSchema, data);
    })
    .filter(_.identity) as PostgresUser[];

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

function parseUserDetailsRecords(records: DynamoDBRecord[]): { upsert: PostgresUserDetail[], remove: string[] } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoUserDetail | undefined;

      return data && morphism(DynamoToPgUserDetailSchema, data);
    })
    .filter(_.identity) as PostgresUserDetail[];

  const deleteIds = records
    .filter(record => record.eventName === 'REMOVE')
    .map(record => {
      const image = record.dynamodb && record.dynamodb.OldImage;
      const data = image && DynamoDB.Converter.unmarshall(image);

      return data && data.user_id;
    })
    .filter(_.identity);
  
  return {
    upsert: upsertRecords,
    remove: deleteIds
  };
}

function parseAccountRecords(records: DynamoDBRecord[]): { upsert: PostgresAccount[], remove: string[] } {
  const upsertRecords = records
    .filter(record => record.dynamodb && record.dynamodb.NewImage)
    .map(record => {
      const image = record.dynamodb && record.dynamodb.NewImage;
      const data = (image && DynamoDB.Converter.unmarshall(image)) as DynamoAccount | undefined;

      return data && morphism(DynamoToPgAccountSchema, data);
    })
    .filter(_.identity) as PostgresAccount[];

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

async function pgUpsertUser(pgClient: pg.Pool, user: PostgresUser): Promise<void> {
 const pgRecord = _.mapValues(
   user,
   (value, column) => 
     value !== undefined && value !== null && jsonColumns.indexOf(column) >= 0 ? 
       JSON.stringify(value) :
       value === undefined ? null : value
 );
 const queryBuilder = squel.useFlavour('postgres')
    .insert()
    .into('"user"');

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
  console.log('UPSERTING USER');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('USER UPSERTED');
  console.log(pgRecord);
}

async function pgUpsertUserDetail(pgClient: pg.Pool, userLocation: PostgresUserDetail): Promise<void> {
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
    .into('"user_detail"');

  _.forEach(pgRecord, (value, column) => {
    queryBuilder.set(`"${ column }"`, value)
  });

  const {
    user_id,
    ...cols
  } = pgRecord;

  queryBuilder.onConflict('user_id', _.mapKeys(cols, (_value, key) => `"${ key }"`));

  const { text, values } = queryBuilder.toParam();

  // DEBUG:
  // tslint:disable
  console.log(JSON.stringify({ text, values }, null, 4));
  console.log('UPSERTING USER DETAIL');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('USER DETAIL UPSERTED');
  console.log(pgRecord);
}

async function pgUpsertAccount(pgClient: pg.Pool, account: PostgresAccount): Promise<void> {
  const pgRecord = _.mapValues(
    account,
    (value, column) =>
      value !== undefined && value !== null && jsonColumns.indexOf(column) >= 0 ?
        JSON.stringify(value) :
        (_.isString(value) && _.isEmpty(value.trim())) || value === undefined ?
          null :
          value
  );
  const queryBuilder = squel.useFlavour('postgres')
    .insert()
    .into('"account"');

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
  console.log('UPSERTING ACCOUNT');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('ACCOUNT UPSERTED');
  console.log(pgRecord);
}

async function pgDeleteUser(pgClient: pg.Pool, id: string): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"user"')
    .where('"id" = ?', id)
    .toParam();

  // DEBUG:
  // tslint:disable
  console.log('DELETING USER');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('USER DELETED');
  console.log(id);
}

async function pgDeleteUserDetail(pgClient: pg.Pool, user_id: string): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"user_detail"')
    .where('"user_id" = ?', user_id)
    .toParam();

  // DEBUG:
  // tslint:disable
  console.log('DELETING USER DETAIL');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('USER DETAIL DELETED');
  console.log(user_id);
}

async function pgDeleteAccount(pgClient: pg.Pool, id: string): Promise<void> {
  const { text, values } = squel.useFlavour('postgres')
    .delete()
    .from('"account"')
    .where('"id" = ?', id)
    .toParam();

  // DEBUG:
  // tslint:disable
  console.log('DELETING ACCOUNT');

  await pgClient.query(text, values);

  // DEBUG:
  // tslint:disable
  console.log('ACCOUNT DELETED');
  console.log(id);
}