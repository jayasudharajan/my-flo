import client from '../../util/dynamoUtil';
import _ from 'lodash';
import EncryptedDynamoTable from './EncryptedDynamoTable';
import UserTable from './UserTable';
import { getFixedTableName } from '../../util/utils';

let userTable = new UserTable();

class UserDetailTable extends EncryptedDynamoTable {

  constructor() {
    super('UserDetail', 'user_id', undefined, ['firstname', 'lastname', 'middlename', 'phone_mobile']);
  }

  /**
   * Retrieve and return UserDetail w/ email.
   */
  retrieveWithUser(user_id) {
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

    return client.batchGet(params).promise()
      .then(result => {
        // TODO: account for more errs.
        let user = result.Responses[getFixedTableName('User')][0];
        let userDetail = result.Responses[getFixedTableName('UserDetail')][0];

        if(_.isEmpty(user) || _.isEmpty(userDetail)) {
          return new Promise((resolve, reject) => {
            resolve([])
          });          
        } else {
          // Add email.
          return Promise.all([
            userTable.decryptProps(user),
            this.decryptProps(userDetail)
          ]);
        }
      })
      .then(([decryptedUser, decryptedUserDetail]) => {
        return {
          ...decryptedUserDetail,
          email: decryptedUser && decryptedUser.email
        };
      });
  }

  batchRetrieveUsers(users) {
    // retrieve User and UserDetail
    let params = {
      RequestItems: {
        [getFixedTableName('UserDetail')]: {
          Keys: []
        }
      }
    };

    users.forEach(user_id => {
      params.RequestItems[getFixedTableName('UserDetail')].Keys.push({ user_id });
    });

    return client.batchGet(params).promise()
      .then(result => {
        let userDetails = result.Responses[getFixedTableName('UserDetail')];

        if(_.isEmpty(userDetails)) {
          return new Promise((resolve, reject) => {
            resolve({})
          });
        } else {
          let decryptQueue = [];
          userDetails.forEach(userDetail => {
            decryptQueue.push(this.decryptProps(userDetail));
          });
          return Promise.all(decryptQueue);
        }
      });
  }

}

export default UserDetailTable;
