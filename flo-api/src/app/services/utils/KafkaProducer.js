import kafka from 'node-rdkafka';
import { encrypt } from '../../../util/encryptionUtils';

class KafkaProducer {

  constructor(kafkaHost, encryptionEnabled, kafkaTimeout, kafkaEncryptionStrategy) {
    this.kafkaHost = kafkaHost;
    this.encryptionEnabled = encryptionEnabled;
    this.kafkaTimeout = kafkaTimeout || 5000;
    this.kafkaEncryptionStrategy = kafkaEncryptionStrategy || {
      encrypt(message) { return encrypt('kafka', message); }
    };
    this.producer = new kafka.Producer({
      'metadata.broker.list': kafkaHost,
      'request.timeout.ms': this.kafkaTimeout
    });
  }

  connect() {
    if (this.producer.isConnected()) {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      const onReady = () => {
        this.producer.removeListener('event.error', onError);
        resolve();
      };
      const onError = err => {
        this.producer.removeListener('ready', onReady);
        reject(err);
      };
      
      this.producer.connect();
      this.producer.once('ready', onReady);
      this.producer.once('event.error', onError);
    });
  }

  send(topic, _messages, sendPlaintext, partitionKey) {
    const messages = Array.isArray(_messages) ? _messages : [_messages];


    return Promise.all(
      [
        this.connect(),
        ...(
          messages.map(message => 
            (!sendPlaintext ? this.encrypt(message) : Promise.resolve(message))
          )
        )
      ]
    )
    .then(([connection, ...messages]) => 
      messages
        .forEach(message => 
          this.producer.produce(topic, null, new Buffer(message), partitionKey, Date.now())
        )
    );
  }

  encrypt(message) {
    return this.encryptionEnabled ?
      this.kafkaEncryptionStrategy.encrypt(message) :
      Promise.resolve(message);
  }
}

export default KafkaProducer;
