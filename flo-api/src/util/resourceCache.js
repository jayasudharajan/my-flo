
module.exports = function (redisClient) {

	this.lookupResources = lookupResources;
	this.cacheResources = cacheResources;
	this.removeResources = removeResources;

	function lookupResources(userId, resourceName) {
		var key = generateKey(userId, resourceName);
		var deferred = Promise.defer();

		redisClient.smembers(key, (err, result) => {

			if (err) {
				deferred.reject(err);
			} else if (result.length) {
				deferred.resolve(result);
			} else {
				deferred.resolve(null);
			}

		});

		return deferred.promise;
	}

	function cacheResources(userId, resourceName, resourceIds) {
		var key = generateKey(userId, resourceName);
		var transaction = redisClient.multi();
		var deferred = Promise.defer();

		resourceIds.forEach(resourceId => transaction.sadd(key, resourceId));
	
		transaction.exec((err, results) => {
			if (err) {
				deferred.reject(err);
			} else {
				deferred.resolve(results);
			}
		});

		return deferred.promise;
	}

	function removeResources(userId, resourceName, resourceIds) {
		var key = generateKey(userId, resourceName);
		var transaction = redisClient.multi();
		var deferred = Promise.defer();

		resourceIds.forEach(resourceId => transaction.srem(key, resourceId));

		transaction.exec((err, results) => {
			if (err) {
				deferred.reject(err);
			} else {
				deferred.resolve(results);
			}
		});

		return deferred.promise;
	}

	function generateKey(userId, resourceName) {
		return 'auth_' + resourceName + '@' + userId;
	}

};