import { ContainerModule } from 'inversify';
import KafkaProducer from '../services/utils/KafkaProducer';
import config from '../../config/config';

export default new ContainerModule((bind, unbind, isBound) => {

  if (!isBound(KafkaProducer)) {
    bind(KafkaProducer).toConstantValue(new KafkaProducer(
      config.kafkaHost,
      config.encryption.kafka.encryptionEnabled,
      config.kafkaTimeout
    ));
  }

});