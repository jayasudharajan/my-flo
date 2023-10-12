import ValidationMixin from '../../models/ValidationMixin';
import CachedDynamoTable from '../../models/cachedDynamoTable';
import TUserToken from './models/TUserToken';
import AWS from 'aws-sdk';
import redis from 'redis';
import DIFactory from  '../../../util/DIFactory';

class UserTokenTable extends ValidationMixin(TUserToken, CachedDynamoTable) {
	constructor(dynamoDbClient, redisClient) {
	    const secondsInADay = 24 * 60 * 60;
		super('UserToken', 'user_id', 'time_issued', secondsInADay, dynamoDbClient, redisClient);
	}
}

export default new DIFactory(UserTokenTable, [AWS.DynamoDB.DocumentClient, redis.RedisClient]);