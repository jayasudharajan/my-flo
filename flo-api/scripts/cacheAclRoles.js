"use strict";

var config = require('../src/config/config');
var Acl = require('acl');
var redis = require('redis');
var roles = require('./aclRoles.json');

console.log(config.redis.url);

var redisClient = redis.createClient('redis://' + config.redis.url, config.redis.options);
var acl = new Acl(new Acl.redisBackend(redisClient));

redisClient.on('ready', () => {
	flushCache(roles)
		.then(() => setPermissions(roles))
		.then(roles => {
			redisClient.quit();
			roles.forEach(role => console.log(role.roles));
		})
		.catch(err => {
			console.log(err);
			redisClient.quit()
		});
});

redisClient.on('error', err => {
	console.log(err);
});



function flushCache(roles) {
	var promises = roles.map(roleDef => {
		var deferred = Promise.defer();

		acl.removeRole(roleDef.roles, err => {
			if (err) {
				deferred.reject(err);
			} else {
				deferred.resolve();
			}
		});

		return deferred.promise;
	});

	return Promise.all(promises);
}

function setPermissions(roles) {
	return new Promise((resolve, reject) =>
		acl.allow(roles, err => {
			if (err) {
				reject(err);
			} else {
				resolve(roles);
			}
		})
	);
}
