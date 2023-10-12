const AuthenticationContainerFactory = require('../../authentication/resources/ContainerFactory');
const redis = require('redis');
const mockRedis = require('redis-mock');
const UserTokenTable = require('../../../../../dist/app/services/legacy-auth/UserTokenTable');
const LegacyAuthService = require('../../../../../dist/app/services/legacy-auth/LegacyAuthService');
const Logger = require('../../../../../dist/app/services/utils/Logger');

function ContainterFactory() {
  const container = AuthenticationContainerFactory();

  container.bind(redis.RedisClient).toConstantValue(mockRedis.createClient());
  container.bind(UserTokenTable).to(UserTokenTable);
  container.bind(LegacyAuthService).to(LegacyAuthService);
  container.bind(Logger).toConstantValue(new Logger());

  return container;
}

module.exports = ContainterFactory;