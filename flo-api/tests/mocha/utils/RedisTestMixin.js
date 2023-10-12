const mockRedis = require('redis-mock');

class RedisTestMixin {
	constructor() {
		this.redisClient = mockRedis.createClient();
	}

	afterEach(done) {
		this.redisClient.flushall(done);
	}
}

module.exports = RedisTestMixin;