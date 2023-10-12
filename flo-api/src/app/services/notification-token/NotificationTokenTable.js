import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import { ValidationMixin, validateMethod } from '../../models/ValidationMixin';
import DynamoTable from '../../models/DynamoTable';
import TNotificationToken from './models/TNotificationToken';
import TDeviceType from './models/TDeviceType';
import AWS from 'aws-sdk';
import { addSetItem, removeSetItem } from '../../../util/utils';
import DIFactory from  '../../../util/DIFactory';

class NotificationTokenTable extends ValidationMixin(TNotificationToken, DynamoTable) {

  constructor(dynamoDbClient) {
    super('NotificationToken', 'user_id', undefined, dynamoDbClient);
  }

  // Add a new token.
  addToken(user_id, token, deviceType) {
    let tokenListName = deviceType + '_tokens';

    return this.retrieve({ user_id })    
      .then(result => {
        // If present, fetch item, add token, update.
        if(!_.isEmpty(result.Item)) {
          let tokenItem = result.Item;
          if(!_.has(tokenItem, tokenListName)) {
            tokenItem[tokenListName] = [];
          }
          addSetItem(tokenItem[tokenListName], token);
          return this.update(tokenItem);
        // If not, create a new one.
        } else {
          let tokenItem = {};
          tokenItem["user_id"] = user_id;          
          tokenItem[tokenListName] = [];
          addSetItem(tokenItem[tokenListName], token);
          return this.create(tokenItem);
        }
      });
  }

  // Remove a token.
  removeToken(user_id, token) {

    // If present, fetch by user_id, remove token, update.
    return this.retrieve({ user_id })
      .then(result => {
        if(!_.isEmpty(result.Item)) {

          let tokenItem = result.Item;

          // Remove regardless of deviceType.
          // TODO: remove hardcoded values.
          if(tokenItem.ios_tokens) {
            removeSetItem(tokenItem['ios_tokens'], token);
          }
          if(tokenItem.android_tokens) {
            removeSetItem(tokenItem['android_tokens'], token);
          }

          return this.update(tokenItem);
        } else {
          return new Promise((resolve, reject) => { reject({ statusCode: 404, message: "User not found." }) });
        }
      });
  }

}

validateMethod(
	NotificationTokenTable.prototype, 
	'addToken', 
	[tcustom.UUIDv4, t.String, TDeviceType]
);

validateMethod(
	NotificationTokenTable.prototype,
	'removeToken',
	[tcustom.UUIDv4, t.String]
);

validateMethod(
	NotificationTokenTable.prototype,
	'retrieveActive',
	[tcustom.UUIDv4]
);

export default new DIFactory(NotificationTokenTable, [AWS.DynamoDB.DocumentClient]);