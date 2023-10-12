import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import { saltAndHashPassword } from '../../../util/encryption';
import TClient from './models/TClient';

class ClientTable extends ValidationMixin(TClient, DynamoTable) {

  constructor(dynamoDbClient) {
    super('Client', 'client_id', undefined, dynamoDbClient);
  }

  create(data) {
    return super.create({
      ...data,
      created_at: new Date().toISOString()
    });
  }

  marshal(data) {
  	return super.marshal({
      ...this._ensureHashedClientSecret(data),
      updated_at: new Date().toISOString()
    });
  }

  marshalPatch(keys, data) {
  	return super.marshalPatch(keys, {
      ...this._ensureHashedClientSecret(data),
      updated_at: new Date().toISOString()
    });
  }

  _ensureHashedClientSecret(data) {
  	if (data.client_secret) {
  		return {
  			...data,
  			client_secret: saltAndHashPassword(data.client_secret)
  		};
  	}

  	return data;
  }

}

export default new DIFactory(ClientTable, [AWS.DynamoDB.DocumentClient]);