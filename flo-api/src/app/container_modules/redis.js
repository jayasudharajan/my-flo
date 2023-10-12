import redis from 'redis';
import { getClient } from '../../util/cache';
import { ContainerModule } from 'inversify';

export default new ContainerModule(bind => {
  bind(redis.RedisClient).toConstantValue(getClient());
});