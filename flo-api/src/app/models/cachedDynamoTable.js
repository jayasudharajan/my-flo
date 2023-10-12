import { cacheLookupWithFallback, getClient, lookupLatest, cacheLatest } from '../../util/cache';
import _ from 'lodash';
import DynamoTable from './DynamoTable';


export default class CachedDynamoTable extends DynamoTable {

	constructor(tableName, keyName, rangeName, cacheTTL, dynamoDbClient, redisClient) {
    	super(tableName, keyName, rangeName, dynamoDbClient);
    	this.redisClient = redisClient || getClient();
    	this.ttl = cacheTTL;
	}

	retrieve(data) {
		const cacheKey = this._generateCacheKey(this.tableName, data[this.keyName], this.rangeName && data[this.rangeName]);

		return this._withCache({
			key: cacheKey,
			fallback: () => super.retrieve(data).then(({ Item }) => Item),
			ttl: this.ttl
		})
		.then(result => ({ Item: result }));
	}

	_withCache({ key, cacheLookup, fallback, cacheInsert, ttl }) {
		const cacheClient = this.redisClient;
	
		return cacheLookupWithFallback({
			cacheLookup: cacheLookup || (() => 
				lookupLatest({ client: cacheClient, key }).then(result => JSON.parse(result))),
			fallback,
			cacheInsert: cacheInsert || (result =>
				this._getTimestamp(result)
					.then(timestamp => 
						cacheLatest({ client: cacheClient, key, data: JSON.stringify(result), ttl, timestamp })
					))
		});
	}

	// Uncached retrieve function
	_retrieve(data) {
		return super.retrieve(data);
	}

	_generateCacheKey(tableName, hashKey, rangeKey) {
		return tableName + '_' + hashKey + (rangeKey ? '_' + rangeKey : '');
	}

	_getTimestamp(data) {
		return new Promise(resolve => resolve(0));
	}
}

