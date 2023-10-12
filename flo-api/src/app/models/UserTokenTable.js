import _ from 'lodash';
import moment from 'moment';
import CachedDynamoTable from './cachedDynamoTable';
import { addUserRoles, createSubResourceRole } from '../../util/aclUtils';

import { getClient } from '../../util/cache';
import ResourceCache from '../../util/resourceCache';

import ICDTable from '../models/ICDTable';
import UserAccountRoleTable from '../models/UserAccountRoleTable';
import UserLocationRoleTable from '../models/UserLocationRoleTable';

import DIFactory from '../../util/DIFactory';
import AWS from 'aws-sdk';

const userAccountRole = new UserAccountRoleTable();
const userLocationRole = new UserLocationRoleTable();
const ICD = new ICDTable();
const resourceCache = new ResourceCache(getClient());

class UserTokenTable extends CachedDynamoTable {

  constructor(dynamoDbClient) {
    const secondsInADay = 24 * 60 * 60;
    super('UserToken', 'user_id', 'time_issued', secondsInADay, dynamoDbClient);
  }

  queryPartition(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      }
    };
    return this.dynamoDbClient.query(params).promise();
  }

  retrieveActiveMobile(user_id) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      FilterExpression: '(#_expiration_time > :now) AND attribute_exists(mobile_device_id)',
      ExpressionAttributeNames: {
        '#_expiration_time': '_expiration_time'
      },
      ExpressionAttributeValues: {
        ':user_id': user_id,
        ':now': moment().unix()
      }
    };

    return this._exhaustiveQuery(params);
  }

  __create(data) {
    return super.create({
      ...data,
      _expiration_time: (data.time_issued || 0) + (data.expiration || 0)
    });
  }

  create(data) {

    return this.__create(data)
      .then(result => 
        initializeUser(data.user_id).then(() => result)
      );
  }

  marshal(data) {
    return super.marshal({
      ...data,
      _expiration_time: (data.time_issued || 0) + (data.expiration || 0)
    });
  }
}

function initializeUser(user_id) {
  let userAccountRoles = [];
  let userLocationRoles = [];

  return Promise.all([
    userAccountRole.retrieveByUserId({ user_id }),
    userLocationRole.retrieveByUserId({ user_id })
  ])
  .then(([userAccountRoleResult, userLocationRoleResult]) => {
    let accountIds = userAccountRoleResult.Items.map(({ account_id }) => account_id);
    let locationIds = userLocationRoleResult.Items.map(({ location_id }) => location_id);

    userAccountRoles = userAccountRoleResult.Items;
    userLocationRoles = userLocationRoleResult.Items;

    resourceCache.cacheResources(user_id, 'Location', locationIds);
    resourceCache.cacheResources(user_id, 'Account', accountIds);

    return retrieveUserDeviceRoles(userLocationRoleResult.Items);
  })
  .then(userDeviceRoles => {
    return assignRoles({ id: user_id }, userAccountRoles, userLocationRoles, userDeviceRoles);
  });
}

function retrieveUserDeviceRoles(userLocationRoles) {

  return Promise.all(
    userLocationRoles.map(({ location_id, roles }) => {
      
      return ICD.retrieveByLocationId({ location_id })
        .then(({ Items }) => {
          return Items.map(({ device_id }) => ({ device_id, roles }));
        });

    })
  )
  .then(locationDeviceRoles => {
    return locationDeviceRoles.reduce((acc, items) => acc.concat(items), []);
  });
}

function assignRoles(user, userAccountRoles, userLocationRoles, userDeviceRoles) {
  let aclAccountRoles = userAccountRoles
    .map(({ account_id, roles }) => 
      roles.map(role =>  createSubResourceRole('Account', account_id, role))
    )
    .reduce((acc, roles) => acc.concat(roles), []);
  let aclLocationRoles = userLocationRoles
    .map(({ location_id, roles }) => 
      roles.map(role => createSubResourceRole('Location', location_id, role))
    )
    .reduce((acc, roles) => acc.concat(roles), []);
  let aclDeviceRoles = userDeviceRoles
    .map(({ device_id, roles }) => 
      roles.map(role => createSubResourceRole('ICD', device_id, role))
    )
    .reduce((acc, roles) => acc.concat(roles), []);

  let aclUserRoles = [
    'user',
    createSubResourceRole('User', user.id, 'self')
  ];
  let aclRoles = aclUserRoles
    .concat(aclAccountRoles)
    .concat(aclLocationRoles)
    .concat(aclDeviceRoles);

  return addUserRoles(user.id, aclRoles);
}

export default new DIFactory(UserTokenTable, [AWS.DynamoDB.DocumentClient]);