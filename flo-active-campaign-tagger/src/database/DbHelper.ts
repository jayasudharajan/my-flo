import _ from 'lodash';
import { DynamoDB } from 'aws-sdk';
import { Icd, User, UserDetails, UserInfo, UserLocationRole } from '../interfaces';
import DynamoDbClient from './dynamo/DynamoDbClient';
import config from '../config';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async retrieveAllUsersAssociatedWithDevice(icdId: string): Promise<UserInfo[]> {
    const icd = await this.dynamoDbClient.get<Icd>('ICD', { id: icdId });

    if (icd === null) {
      console.log(`ICD with ID ${icdId} not found`);
      return Promise.resolve([]);
    }

    const userLocationRoles = await this.dynamoDbClient.query<UserLocationRole>('UserLocationRole', {
      IndexName: 'LocationIdIndex',
      KeyConditionExpression: 'location_id = :location_id',
      ExpressionAttributeValues: {
        ':location_id': icd.location_id
      }
    });

    if (_.isEmpty(userLocationRoles)) {
      console.warn(`Empty UserLocationRoles for Location with ID ${icd.location_id} and ICD with ID ${icdId}`);
      return Promise.resolve([]);
    }

    const users = await Promise.all(userLocationRoles.map(async userLocationRole => {
      const user = await this.dynamoDbClient.get<User>('User', { id: userLocationRole.user_id });
      const userDetails = await this.dynamoDbClient.get<UserDetails>('UserDetail', { user_id: userLocationRole.user_id });

      if (_.isNil(user) || _.isNil(userDetails)) {
        console.warn(`User or UserDetails with ID ${userLocationRole.user_id} not found.`);
        return null;
      }

      return {
        email: user.email,
        firstName: userDetails.firstname,
        lastName: userDetails.lastname
      }
    }));

    return _.compact(users);
  }

  public async retrieveUserEmail(userId: string): Promise<string> {
    const user = await this.dynamoDbClient.get<User>('User', { id: userId });

    if (_.isNil(user)) {
      return Promise.reject(`User with ID ${userId} not found.`);
    }

    return user.email;
  }
}

const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);
Object.freeze(dbHelper);

export default dbHelper;