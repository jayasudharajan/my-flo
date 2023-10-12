import redis from 'redis';
import config from '../config/config';

let redisClient = null;

export function getClient() {
	if (!redisClient) {
		redisClient = createClient();
	}

	return redisClient;
}

export function createClient() {
	const redisClientOptions = config.redis.options || {};
	return redis.createClient('redis://' + config.redis.url, {
		retry_strategy({ total_retry_time, attempt }) {
		        if (total_retry_time > 1000 * 60 * 60) {
		            // End reconnecting after a specific timeout and flush all commands with a individual error
		            return new Error('Retry time exhausted');
		        } else if (attempt > 10) {
		            // End reconnecting with built in error
		            return undefined;
		        } else {
		        	return Math.min(attempt * 100, 3000);
		        }
		},
		...redisClientOptions
	});
}

// Deprecated
export function withFallback(cacheLookup, fallback, cacheInsert, cb) {
	try {
		return cacheLookup()
			.then(result => {
				if (result) {
					if (cb) { 
						cb(true, result); 
					}
					return result;
				} else {
					return fallback()
						.then(fallbackResult => {
							if (fallbackResult) {
								cacheInsert(fallbackResult);
							} else {
								return new Promise((resolve, reject) => reject({ error: true, message: 'Fall back to DB failed' }));
							}

							if (cb) {
								cb(false, fallbackResult);
							}
							
							return fallbackResult;
						});
				}
			});
	} catch (err) {
		return new Promise((resolve, reject) => reject(err));
	}
}

export function cacheLookupWithFallback({ cacheLookup, fallback, cacheInsert }) {
	try {
		return cacheLookup()
			.then(result => {
				if (result) {
					return { ...result, _isFromCache: true };
				}
				
				return fallback();
			})
			.then(result => {
				if (cacheInsert && result && !result._isFromCache) {
					cacheInsert(result);
				} 

				return result;
			});
	} catch (err) {
		return new Promise((resolve, reject) => reject(err));
	}
}

export function lookupLatest({ client, key }) {
	let deferred = Promise.defer();

	(client || getClient())
		.zrevrange(key, 0, 0, (err, data) => {
			if (err) {
				deferred.reject(err);
			} else {
				deferred.resolve(data[0] || null);
			}
	});

	return deferred.promise;
}

export function cacheLatest({ client, timestamp, key, data, ttl }) {
	let deferred = Promise.defer();
	let transaction = (client || getClient()).multi();

	transaction.zadd(key, timestamp || 0, data);

	if (ttl) {
		transaction.expire(key, ttl);
	}

	transaction.exec(err => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve();
		}
	});

	return deferred.promise;
}