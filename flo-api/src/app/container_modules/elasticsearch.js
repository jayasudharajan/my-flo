import config from '../../config/config';
import { ContainerModule } from 'inversify';
import elasticsearch from 'elasticsearch';

export default new ContainerModule(bind => {
  const elasticsearchClient = new elasticsearch.Client({
    host: config.elasticSearchHost
  });

  bind(elasticsearch.Client).toConstantValue(elasticsearchClient);
});