import client from '../../util/dynamoUtil';
import uuid from 'node-uuid';
import _ from 'lodash';
import EncryptedDynamoTable from './EncryptedDynamoTable';
import { addHashedPassword, hmac } from '../../util/encryption';
import { getFixedTableName } from '../../util/utils';
import RegistrationTokenTable from '../models/RegistrationTokenTable';
import NotificationTokenTable from '../services/notification-token/NotificationTokenTable';


let registrationToken = new RegistrationTokenTable();

class UserTable extends EncryptedDynamoTable {

  constructor() {
    super('User', 'id', undefined, ['email']);
  }

  /**
   * Create a User, accounting for unique email and hashing password.
   */
  create(data) {

    // Check range key, if exists in table.
    if(this.haveRangeName && !data[this.rangeName]) {
      return new Promise((resolve, reject) => {
        reject({ message: 'Range key "' + this.rangeName + '" required.'})
      });
    }
    // Generates hashKeys and/or rangeKeys values for known keyNames if none exist.
    // Otherwise if keys are provided, is an implied update.
    if(!data[this.keyName]) {
      data[this.keyName] = uuid.v4();
    }

    // Encrypt password if present.
    if(data.password) {
      data = addHashedPassword(data);
    }

    if (data.email) {
      data.email = data.email.toLowerCase().trim();
    }

    // Make 'active' unless directed otherwise.
    if(typeof(data.is_active) === undefined) {
      data.is_active = true;
    }

    // TODO: capture both user and userrole to send back to client?

    return this.ensureUniqueEmail(data.email)
      .then(result => this.encryptProps(data))
      .then(encryptProps => {
        let params = {
          TableName: this.tableName,
          Item: encryptProps
        };

        return client.put(params).promise()
            .then(result => {
              // NOTE: if empty, means was successful.
              // Return back the item with id.
              if(_.isEmpty(result)) {
                return new Promise((resolve, reject) => {
                  resolve(data);
                });
              } else {
                return new Promise((resolve, reject) => {
                  reject({ message: "Unable to create item."})
                });
              }
            });
      });

  }

  /**
   * Update a user.
   */
  update(data) {

    let keys = {};

    // Extract keys.
    keys[this.keyName] = data[this.keyName];

    // Encrypt password if present.
    if(data.password ) {
      data = addHashedPassword(data);
    }

    if (data.email) {
      data.email = data.email.toLowerCase().trim();
    }

    // Retrieve.
    return (data.email ? this.ensureUniqueEmail(data.email, keys.id) : new Promise(resolve => resolve()))
      .then(() => this.encryptProps(data))
      .then(encryptedProps => {
        let params = {
          TableName: this.tableName,
          Item: encryptedProps,
          ConditionExpression: 'attribute_exists(#keyName)',
          ExpressionAttributeNames: {
            '#keyName': this.keyName
          }
        };

        return client.put(params).promise();
      })
      .catch(err => {
        if (err.code === 'ConditionalCheckFailedException') {
          throw { message: "User not found."};
        } else {
          throw err;
        }
      });
  }

  /**
   * Partial update of an user.
   */
  patch(keys, data) {

    let update_expression = "SET";
    let expression_attribute_names = {};
    let attribute_values = {};

    // Encrypt password if present.
    if(data.password) {
      data = addHashedPassword(data);
    }

    if (data.email) {
      data.email = data.email.toLowerCase().trim();
    }

    return (data.email ? this.ensureUniqueEmail(data.email, keys.id) : new Promise(resolve => resolve()))
      .then(() => super.patch(keys, data));
  }

  /**
   * Retrieve a user based on email.  Uses a GSI.
   */
  getUserByEmail(email) {
    let params = {
      TableName: this.tableName,
      IndexName: "EmailIndex",
      KeyConditionExpression: "email = :email",
      ExpressionAttributeValues: { 
        ":email": email.toLowerCase().trim()
      },
      "ProjectionExpression": "email,id,password,is_active,is_system_user"
    };

    return this.decryptScan(client.query(params).promise());
  }

  // FOR TESTING ONLY!
  scanEmail() {
    let params = {
      TableName: this.tableName,
      IndexName: "UserEmail"
    };
    return this.decryptScan(client.scan(params).promise());
  }
  getUsersNotificationTokens() {
    let params = {
      TableName: getFixedTableName("notificationToken"),
      IndexName: "userID"
    };
    return client.scan(params).promise();
  }

  // TODO:
  sendRegistrationMail(user_id) {

    return registrationToken.create({ user_id });

  }

  ensureUniqueEmail(email, user_id) {
    return this.getUserByEmail(email)
      .then(({ Items }) => {
        if (!_.isEmpty(Items) && (!user_id || Items.some(({ id }) => id !== user_id))) {
          throw { message: "Email is already associated with a user." };
        }
      });
  }

  marshal(data) {
    return super.marshal(_.omit(data, ['_is_ip_restricted']));
  }

  marshalPatch(keys, data) {
    return super.marshalPatch(keys, _.omit(data, ['_is_ip_restricted']));
  }

}

export default UserTable;
