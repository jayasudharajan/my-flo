"use strict";

var config = require('../src/config/config');
var Acl = require('acl');
var redis = require('redis');
var patterns = require('./flushCache.json');

console.log(config.redis.url);

var redisClient = redis.createClient('redis://' + config.redis.url, config.redis.options);
var acl = new Acl(new Acl.redisBackend(redisClient));

redisClient.on('ready', () => {
	Promise.all(patterns.map(getKeys))
		.then(results => {
			var keys = (results ).reduce((acc, x) => acc.concat(x), []);

			return flushKeys(keys);
		})
		.then(() => redisClient.quit())
		.catch(err => {
			console.log(err);
			redisClient.quit();
		});
});

redisClient.on('error', err => {
	console.log(err);
});


function getKeys(pattern) {
	var deferred = Promise.defer();

	redisClient.keys(pattern, (err, result) => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve(result);
		}
	});

	return deferred.promise;
}

function flushKeys(keys) {
	var deferred = Promise.defer();

	redisClient.del(keys, (err, result) => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve(result);
		}
	});

	return deferred.promise;
}