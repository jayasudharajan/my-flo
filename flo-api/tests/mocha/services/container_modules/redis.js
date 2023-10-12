const inversify = require('inversify');
const redis = require('redis');
const mockRedis = require('redis-mock');

module.exports = new inversify.ContainerModule((bind, unbind, isBound) => {
  
  if (!isBound(redis.RedisClient)) {
    bind(redis.RedisClient).toConstantValue(mockRedis.createClient());
  }
});