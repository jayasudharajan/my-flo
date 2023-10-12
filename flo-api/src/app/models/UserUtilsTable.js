import client from '../../util/dynamoUtil';
import uuid from 'node-uuid';
import _ from 'lodash';
import { addHashedPassword, hmac } from '../../util/encryption';
import { getFixedTableName } from '../../util/utils';

import UserTable from '../models/UserTable';
import UserDetailTable from '../models/UserDetailTable';
import AccountTable from '../models/AccountTable';
import AccountGroupTable from '../models/AccountGroupTable';
import ICDTable from '../models/ICDTable';

import UserAccountRoleTable from '../models/UserAccountRoleTable';
import UserLocationRoleTable from '../models/UserLocationRoleTable';
import LocationTable from '../models/LocationTable';

// TODO: account for all functions that involve UserRole.


class UserUtilsTable {

  constructor() {
    this.user = new UserTable();
    this.userDetail = new UserDetailTable();
    this.account = new AccountTable();
    this.accountGroup = new AccountGroupTable();
    this.icd = new ICDTable();
    this.userAccountRole = new UserAccountRoleTable();
    this.userLocationRole = new UserLocationRoleTable();
    this.location = new LocationTable();    
  }

  // TODO: refactor to do all as batch.
  retrieveUserForAuthToken(user_id) {

    // Get User.
    let params = {
      RequestItems: {
        [getFixedTableName('User')]: {
          Keys: [{
              id: user_id
          }]
        }
      }
    };

    // Get UserAccountRole(s) and UserLocationRole(s).
    let paramsAccountRole = {
      TableName: getFixedTableName("UserAccountRole"),
      KeyConditionExpression: "user_id = :user_id",
      ExpressionAttributeValues: {
        ":user_id": user_id
      }
    };
    let paramsLocationRole = {
      TableName: getFixedTableName("UserLocationRole"),
      KeyConditionExpression: "user_id = :user_id",
      ExpressionAttributeValues: {
        ":user_id": user_id
      }
    };

    let thisUser = {};

    return client.batchGet(params).promise()
      .then(result => {
        thisUser = {
          ...result.Responses[getFixedTableName('User')][0] 
        };
        return this.user.decryptProps(thisUser);
      })
      .then(decryptedUser => {
        let query_queue = [
          client.query(paramsAccountRole).promise(),
          client.query(paramsLocationRole).promise()
        ];

        thisUser = decryptedUser;

        return Promise.all(query_queue);
      })
      .then(values => {

        thisUser.accounts = [];
        thisUser.locations = [];

        // Add accounts and locations if present.
        for(let item of values[0].Items) {
          thisUser.accounts.push(item.account_id);
        }
        for(let item of values[1].Items) {
          thisUser.locations.push(item.location_id);
        }

        return new Promise((resolve, reject) => {
          resolve(thisUser);
        });
      });
  }

  retrieveWholeUser(user_id) {
    // retrieve User and UserDetail
    let params = {
      RequestItems: {
        [getFixedTableName('User')]: {
          Keys: [{
              id: user_id
          }]
        },
        [getFixedTableName('UserDetail')]: {
          Keys: [{
              user_id
          }]
        }
      }
    };
    // query UserAccountRole and UserLocationRole
    let paramsAccountRole = {
      TableName: getFixedTableName("UserAccountRole"),
      KeyConditionExpression: "user_id = :user_id",
      ExpressionAttributeValues: {
        ":user_id": user_id
      }
    };
    let paramsLocationRole = {
      TableName: getFixedTableName("UserLocationRole"),
      KeyConditionExpression: "user_id = :user_id",
      ExpressionAttributeValues: {
        ":user_id": user_id
      }
    };

    let response = {};
    return client.batchGet(params).promise()
      .then(result => {
        let userResult = result.Responses[getFixedTableName('User')][0];
        let userDetailResult = result.Responses[getFixedTableName('UserDetail')][0];
        if(!userDetailResult) userDetailResult = {};
        return Promise.all([
          this.user.decryptProps(userResult),
          this.userDetail.decryptProps(userDetailResult)
        ]);
      })
      .then(([decryptedUser, decryptedUserDetail]) => {

        response = {
          ...decryptedUser,
          ...decryptedUserDetail
        };

        let query_queue = [
          client.query(paramsAccountRole).promise(),
          client.query(paramsLocationRole).promise()
        ];
        return Promise.all(query_queue);
      })
      .then(values => {
        response.accounts = values[0].Items;
        response.locations = values[1].Items;
        return new Promise((resolve, reject) => {
          resolve(response);
        });
      });
  }

  createWholeUser(dataUser, dataUserDetail) {
    // create user & user role
    return this.user.create(dataUser)
      .then(result => {
        // create user detail
        if(result.id) {
          dataUserDetail.user_id = result.id;
          return this.userDetail.create(dataUserDetail);
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Unable to create item."});
          });
        }
      });
  }

  /**
   * Creates a new Account and Location for a User along with 'owner' roles.
   *
   * NOTE: This will create new items regardless of their existing Account.
   *       So - it should be controlled from the client implementation.
   * 
   */
  createNewAccount(data) {
    let account_id = uuid.v4();
    let location_id = uuid.v4();
    let user_id = data.user_id;

    // If no group_name present, set to 'default'.
    // Otherwise look up group_id based on group_name.
    // TODO: prevent someone from being able to add an Account to 
    // a group they don't have permission for.    
    let group_name = "default";
    if(data.group_name) group_name = data.group_name;

    let accountData = {};
    accountData.id = account_id;
    accountData.owner_user_id = user_id;
    
    return this.accountGroup.retrieveByName({ name: group_name })
      .then(group => {

        if(_.isEmpty(group.Items)) {
          return new Promise((resolve, reject) => {
            reject({ message: "Account not created.  No valid group found."});
          });
        } else {

          // Fetch the group_id and add to Account.
          accountData.group_id = group.Items[0].id;

          // Fill in other Location params for defaults.
          // TODO: put defaults in config and account for non-defaults.
          let locationData = {
            location_id,
            account_id,
            location_name: "Home",
            location_type: "sfh",
            country: "USA",
            timezone: "America/Los_Angeles",
            gallons_per_day_goal: 240
          };

          return this.location.encryptProps(locationData)
            .then(encryptedLocationData => {

              let params = {
                RequestItems: {
                  [getFixedTableName('Account')]: [{
                    PutRequest: {
                      Item: accountData
                    }
                  }],
                  [getFixedTableName('Location')]: [{
                    PutRequest: {
                      Item: encryptedLocationData
                    }
                  }]
                }
              };

              // Create Account and Location.
              return client.batchWrite(params).promise();

            })
            .then(result => {
              if(_.isEmpty(result.UnprocessedItems)) {

                let newUserAccountRole = {
                  user_id: user_id,
                  account_id: account_id,
                  roles: ["owner"]
                } 

                let newUserLocationRole = {
                  user_id: user_id,
                  account_id: account_id,
                  location_id: location_id,
                  roles: ["owner"]
                }

                let params = {
                  RequestItems: {
                    [getFixedTableName('UserAccountRole')]: [{
                      PutRequest: {
                        Item: newUserAccountRole
                      }
                    }],
                    [getFixedTableName('UserLocationRole')]: [{
                      PutRequest: {
                        Item: newUserLocationRole
                      }
                    }]
                  }
                }

                // Create UserAccountRole and UserLocationRole.
                return client.batchWrite(params).promise();

              } else {
                return new Promise((resolve, reject) => {
                  reject({ message: "Unable to create Account or location."}) // TODO: include UnprocessedItems.
                });
              }

            })
            .then(result => {
              if(_.isEmpty(result.UnprocessedItems)) {
                // If everything is created, return new Account and Location ids.
                return new Promise((resolve, reject) => {
                  resolve({ account_id, location_id })
                });
              } else {
                return new Promise((resolve, reject) => {
                  reject({ message: "Unable to create Roles."}) // TODO: include UnprocessedItems.
                });
              }

            });
          
        }

      })    

  }

  retrieveICDsbyAccountIds(account_ids) {
    // cannot batch query, do promise.all
    let query_set = [];
    for(let index in account_ids) {
      let account_id = account_ids[index];
      let params = {
        TableName: getFixedTableName("Location"),
        KeyConditionExpression: "account_id = :account_id",
        ExpressionAttributeValues: {
          ":account_id": account_id
        }
      };
      query_set.push(client.query(params).promise());
    }
    return Promise.all(query_set)
      .then(values => {
        let location_query_set = [];
        for(let index in values) {
          let value = values[index];
          for(let location_index in value.Items) {
            let location = value.Items[location_index];
            let params = {
              TableName: getFixedTableName("ICD"),
              IndexName: "LocationIdIndex",
              KeyConditionExpression: "location_id = :location_id",
              ExpressionAttributeValues: {
                ":location_id": location.location_id
              }
            };
            location_query_set.push(client.query(params).promise());
          }
        }
        return Promise.all(location_query_set);
      })
      .then(values => {
        let icds = [];
        for(let location_index in values) {
          let locations = values[location_index].Items;
          for(let index in locations) {
            let location = locations[index];
            icds.push(location.device_id);
          }
        }
        return new Promise((resolve, reject) => {
            resolve(icds);
          });
      });
  }

  retrieveICDsbyUserId(user_id) {
    return this.account.retrieveAccountsForOwner({ owner_user_id: user_id })
    .then(result => {
      let accounts = result.Items;
      let account_ids = [];
      for(let i = 0; i < accounts.length; i++) {
        account_ids.push(accounts[i].id);
      }
      return this.retrieveICDsbyAccountIds(account_ids);
    });
  }

  getUserWholePatchParam(table_name, keys, data) {
    let update_expression_update = "SET";
    let update_expression_remove = "REMOVE";
    let expression_attribute_names = {};
    let attribute_values = {};

    // Create update expression and values.
    for(let data_key in data) {
      // Account for reserved words conflicts using aliases.
      if(data[data_key] === '') {
        update_expression_remove += " #" + data_key + ",";
      } else {
        update_expression_update += " #" + data_key + " = :" + data_key + ",";
        attribute_values[":" + data_key]= data[data_key];
      }
      expression_attribute_names["#" + data_key] = data_key;
    }
    // removes comma and combine update & remove
    let update_expression = '';
    if(update_expression_update != 'SET') update_expression = update_expression_update.substr(0, update_expression_update.length - 1);
    if(update_expression_remove != 'REMOVE') {
      if(update_expression != '') update_expression += ' ';
      update_expression += update_expression_remove.substr(0, update_expression_remove.length - 1);
    }

    let params = {
      TableName: table_name,
      Key: keys,
      UpdateExpression: update_expression,
      ExpressionAttributeNames: expression_attribute_names,
      ExpressionAttributeValues: attribute_values,
      ReturnValues: "UPDATED_NEW"
    };

    return params;
  }

  patchWholeUser(user_id, userData, userDetail) {
    // Encrypt password if present.
    // NOTE:  should this even be here any more?
    if(userData.password) {
      userData = addHashedPassword(userData);
    }

    let encryptedUserDetail = {};

    return this.userDetail.encryptProps(userDetail)
      .then(encryptedUserDetailResult => {
        encryptedUserDetail = encryptedUserDetailResult;
        if (userData.email) {
          userData.email = userData.email.trim().toLowerCase();
        }
        return this.user.encryptProps(userData)
      })
      .then(encryptedUser => {

        let userParams = this.getUserWholePatchParam(getFixedTableName('User'), {id: user_id}, encryptedUser);
        let userDetailParams = this.getUserWholePatchParam(getFixedTableName('UserDetail'), {user_id}, encryptedUserDetail);

        let patch_queue = [];
        // prevent empty patch
        if(!_.isEmpty(userData)) patch_queue.push(
          (userData.email ? this.user.ensureUniqueEmail(userData.email, user_id) : new Promise(resolve => resolve()))
            .then(() => client.update(userParams).promise())
        );
        if(!_.isEmpty(userDetail)) patch_queue.push(client.update(userDetailParams).promise());

        return Promise.all(patch_queue);
      });
  }

  removeWholeUser(user_id) {
    // remove user and user device
    let remove_set = [];
    remove_set.push(this.user.remove({ id: user_id }));
    remove_set.push(this.userDetail.remove({ user_id }));
    // query all rows on role table
    remove_set.push(this.userAccountRole.retrieveByUserId({ user_id }));
    remove_set.push(this.userLocationRole.retrieveByUserId({ user_id }));
    return Promise.all(remove_set)
      .then(values => {
        let success = true;
        for(let i = 0; i < remove_set.length - 2; i++) {
          if(!_.isEmpty(values[i])) success = false;
          break;
        }
        if(success) {
          let remove_role_set = [];
          let params = {
            RequestItems: {
              [getFixedTableName('UserAccountRole')]: [],
              [getFixedTableName('UserLocationRole')]: []
            }
          };
          // check if empty, return success
          if(values[remove_set.length - 2].Items.length === 0 &&
             values[remove_set.length - 1].Items.length === 0) {
            return new Promise((resolve, reject) => {
              resolve({ user_id });
            });
          }
          // UserAccountRole
          values[remove_set.length - 2].Items.forEach(result => {
            params.RequestItems[getFixedTableName('UserAccountRole')].push({
              DeleteRequest:
              { Key: { user_id, account_id: result.account_id }}
            });
          });
          // UserLocationRole
          values[remove_set.length - 1].Items.forEach(result => {
            params.RequestItems[getFixedTableName('UserLocationRole')].push({
              DeleteRequest:
              { Key: { user_id, location_id: result.location_id }}
            });
          });
          return client.batchWrite(params).promise();
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Delete action failed."});
          });
        }
      })
      .then(result => {
        if(_.isEmpty(result.UnprocessedItems)) {
          return new Promise((resolve, reject) => {
            resolve({ user_id });
          });
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Unable to remove Roles.", error: result.UnprocessedItems});
          });
        }
      });
  }

  retrieveUserbyLocationId(location_map) {
    let user_map = {};
    let query_location_queue = [];
    // query user_id from location role
    for(let location_id in location_map) {
      query_location_queue.push(this.userLocationRole.retrieveByLocationId({location_id}));
    }
    return Promise.all(query_location_queue)
      .then(values => {
        let user_keys = [];
        values.forEach(result => {
          if(result.Items) {
            result.Items.forEach(locationRole => {
              if(!(locationRole.user_id in user_map)) {
                user_map[locationRole.user_id] = { device_ids: [] };
                user_keys.push({ id: locationRole.user_id });
              }
              user_map[locationRole.user_id].device_ids.push( ...location_map[locationRole.location_id] );
            });
          }
        });
        if(user_keys.length == 0) {
          return new Promise((resolve, reject) => {
            reject({ message: 'Location not found.', statusCode: 404});
          });
        } else {
          // query email from user
          let params = {
            RequestItems: {
              [getFixedTableName('User')]: {
                Keys: user_keys
              }
            }
          };
          return client.batchGet(params).promise();
        }
      })
      .then(result => {
        // put information with pre-defined format
        if(result.Responses[getFixedTableName('User')]) {
          return Promise.all(result.Responses[getFixedTableName('User')]
            .map(user => this.user.decryptProps(user))
          );
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: 'User not found.', statusCode: 404});
          });
        }
      })
      .then(decryptedUsers => {
        decryptedUsers
          .forEach(user => user_map[user.id].email = user.email);
        
        return user_map;
      });
  }

  scanUserbyDeviceId() {
    // scan all device id
    return this.icd.scanAll()
      .then(result => {
        let icdrows = result.Items;
        let location_map = {};
        icdrows.forEach(icd => {
          if(!(icd.location_id in location_map)) {
            location_map[icd.location_id] = [];
          }
          location_map[icd.location_id].push(icd.device_id);
        });
        if(icdrows.length == 0) {
          return new Promise((resolve, reject) => {
            reject({ message: 'Device not found.', statusCode: 404});
          });
        } else {
          return this.retrieveUserbyLocationId(location_map);
        }
      });
  }

  retrieveUserbyDeviceId(device_id) {
    // if no specific device id, scan all.
    if(!device_id) return this.scanUserbyDeviceId();
    return this.icd.retrieveByDeviceId({ device_id })
      .then(result => {
        let icdrows = result.Items;
        if(icdrows.length == 1) {
          return this.retrieveUserbyLocationId({ [result.Items[0].location_id]: [device_id] });
        } else {
          return new Promise((resolve, reject) => {
            reject((icdrows.length == 0)?
                    { message: 'Device not found.', statusCode: 404}:
                    { message: 'Device assigned to multi-location.', statusCode: 400});
          });
        }
      });
  }

  searchUserByEmail(email) {
    return this.user.getUserByEmail(email)
      .then(result => {
        if(result.Items) {
          // for now, it should be one row.
          return this.retrieveWholeUser(result.Items[0].id);
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "User Not Found", statusCode: 404})
          });
        }
      });
  }

  retrieveUserByGroup(group_id) {
    let params = {
      RequestItems: {
        [getFixedTableName('User')]: {
          Keys: []
        },
        [getFixedTableName('UserDetail')]: {
          Keys: []
        }
      }
    };
    return this.account.retrieveAccountsForGroup({ group_id })
      .then(result => {
        if(_.isUndefined(result.Items) || _.isEmpty(result.Items)) {
          return new Promise((resolve, reject) => { reject({ status: 404, message: "Group not found."}) });
        } else {
          result.Items.forEach(account => {
            params.RequestItems[getFixedTableName('User')].Keys.push({ id: account.owner_user_id });
            params.RequestItems[getFixedTableName('UserDetail')].Keys.push({ user_id: account.owner_user_id });
          });
          return client.batchGet(params).promise()
        }
      })
      .then(result => {
        let decryptQueue = [];
        result.Responses[getFixedTableName('User')].forEach(user => {
          let userResult = { ...user };
          decryptQueue.push(this.user.decryptProps(userResult));
        });
        result.Responses[getFixedTableName('UserDetail')].forEach(userDetail => {
          let userDetailResult = { ...userDetail };
          decryptQueue.push(this.userDetail.decryptProps(userDetailResult));
        });
        return Promise.all(decryptQueue);
      })
      .then(values => {
        let hashUsers = {};
        values.forEach(value => {
          let user_id = value.id;
          if(_.isUndefined(user_id)) user_id = value.user_id;
          // if there is no id/user_id, drop this row
          if(!_.isUndefined(user_id)) {
            if(_.isUndefined(hashUsers[user_id])) {
              hashUsers[user_id] = { ...value };
            } else {
              hashUsers[user_id] = Object.assign({}, hashUsers[user_id], value);
            }
          }
        });
        let users = [];
        for(let hashuser_id in hashUsers) {
          users.push(hashUsers[hashuser_id]);
        }
        return new Promise((resolve, reject) => { resolve(users) });
      });
  }

  retrieveUserICDByGroup(group_id) {
    let hashUsers = {};
    let users = {};
    let accounts = {};
    let queryLocationQueue = [];
    let params = {
      RequestItems: {
        [getFixedTableName('User')]: {
          Keys: []
        }
      }
    };
    return this.account.retrieveAccountsForGroup({ group_id })
      .then(result => {
        if(_.isUndefined(result.Items) || _.isEmpty(result.Items)) {
          return new Promise((resolve, reject) => { reject({ status: 404, message: "Group not found."}) });
        } else {
          result.Items.forEach(account => {
            queryLocationQueue.push(this.location.retrieveByAccountId({ account_id: account.id }));
            params.RequestItems[getFixedTableName('User')].Keys.push({ id: account.owner_user_id });
            if(_.isUndefined(users[account.owner_user_id])) users[account.owner_user_id] = [];
            users[account.owner_user_id].push(account.id);
          });
          return client.batchGet(params).promise()
        }
      })
      .then(result => {
        let decryptQueue = [];
        result.Responses[getFixedTableName('User')].forEach(user => {
          let userResult = { ...user };
          decryptQueue.push(this.user.decryptProps(userResult));
        });
        return Promise.all(decryptQueue);
      })
      .then(values => {
        values.forEach(value => {
          let user_id = value.id;
          if(_.isUndefined(user_id)) user_id = value.user_id;
          // if there is no id/user_id, drop this row
          if(!_.isUndefined(user_id)) {
            hashUsers[user_id] = { email: value.email };
          }
        });
        return Promise.all(queryLocationQueue);
      })
      .then(values => {
        let queryICDQueue = [];
        values.forEach(value => {
          if(value.Items) {
            value.Items.forEach(location => {
              if(_.isUndefined(accounts[location.account_id])) accounts[location.account_id] = [];
              accounts[location.account_id].push(location.location_id);
              queryICDQueue.push(this.icd.retrieveByLocationId({ location_id: location.location_id }));
            });
          }
        });
        return Promise.all(queryICDQueue);
      })
      .then(values => {
        let locations = {};
        values.forEach(value => {
          if(value.Items) {
            value.Items.forEach(icd => {
              if(_.isUndefined(locations[icd.location_id])) locations[icd.location_id] = [];
              locations[icd.location_id].push(icd.device_id);
            });
          }
        });
        for(let user_id in hashUsers) {
          hashUsers[user_id].device_ids = [];
          if(user_id in users) {
            users[user_id].forEach(account_id => {
              if(account_id in accounts) {
                accounts[account_id].forEach(location_id => {
                  if(location_id in locations) {
                    locations[location_id].forEach(icd_id => {
                      if(hashUsers[user_id].device_ids.indexOf(icd_id) < 0) {
                        hashUsers[user_id].device_ids.push(icd_id);
                      }
                    });
                  }
                });
              }
            });
          }
          if(hashUsers[user_id].device_ids.length === 0) delete hashUsers[user_id];
        }
        return new Promise((resolve, reject) => { resolve(hashUsers) });
      });
  }
}

export default UserUtilsTable;