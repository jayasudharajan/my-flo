
module.exports = function (redisClient) {

	this.lookupByLocationId = lookupByLocationId;
	this.lookupByAccountId = lookupByAccountId;
	this.lookupByUserId = lookupByUserId;
	this.lookupByResourceId = lookupByResourceId;
	this.cacheLocationId = cacheLocationId;
	this.cacheAccountId = cacheAccountId;
	this.cacheUserId = cacheUserId;
	this.cacheResource = cacheResource;
	this.removeResource = removeResource;
	

	function lookupByLocationId(location_id, withTimestamp) {
		return lookupByResourceId('location', location_id, withTimestamp);
	}

	function lookupByAccountId(account_id, withTimestamp) {
		return lookupByResourceId('account', account_id, withTimestamp);
	}

	function lookupByUserId(user_id, withTimestamp) {
		return lookupByResourceId('user', user_id, withTimestamp);
	}

	function lookupByResourceId(resourceType, resourceId, withTimestamp) {
		var deferred = Promise.defer();
		var key = generateKey(resourceType, resourceId);
		var args = [key, 0, 0].concat(withTimestamp ? ['WITHSCORES'] : []);

		redisClient
			.zrevrange(args, (err, data) => {

				if (err) {
					deferred.reject(err);
				} else if (withTimestamp && data && data.length > 1) {
					deferred.resolve({
						group_id: data[0],
						created_at: data[1]
					});
				} else {
					deferred.resolve(data && data.length ? data[0] : null);
				}
			});

		return deferred.promise;
	}

	function cacheLocationId(group_id, location_id, timestamp) {
		return cacheResource(group_id, 'location', location_id, timestamp);
	}

	function cacheAccountId(group_id, account_id, timestamp) {
		return cacheResource(group_id, 'account', account_id, timestamp);
	}

	function cacheUserId(group_id, user_id, timestamp) {
		return cacheResource(group_id, 'user', user_id, timestamp);
	}

	function cacheResource(groupId, resourceType, resourceId, timestamp) {
		var deferred = Promise.defer();
		var key = generateKey(resourceType, resourceId);

		redisClient.zadd(key, timestamp || 0, groupId, (err, result) => {
			if (!err) {
				deferred.resolve(result);
			} else {
				deferred.reject(err);
			}
		});

		return deferred.promise;
	}

	function removeResource(resourceType, resourceId) {
		var deferred = Promise.defer();
		var key = generateKey(resourceType, resourceId);

		redisClient.del(key, (err, result) => {
			if (!err) {
				deferred.resolve(result);
			} else {
				deferred.reject(err);
			}
		});

		return deferred.promise;
	}

	function generateKey(resourceType, resourceId) {
		return 'resource@' + resourceType + '.' + resourceId + '.group';
	}
}