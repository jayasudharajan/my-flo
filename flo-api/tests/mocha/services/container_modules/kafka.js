const inversify = require('inversify');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');

module.exports = new inversify.ContainerModule((bind, unbind, isBound) => {

  if (!isBound(KafkaProducer)) {
    bind(KafkaProducer).toConstantValue(new KafkaProducerMock());
  }
});