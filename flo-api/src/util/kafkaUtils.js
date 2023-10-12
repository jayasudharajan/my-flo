import config from '../config/config';
import KafkaProducer from '../app/services/utils/KafkaProducer';

const kafkaProducer = new KafkaProducer(config.kafkaHost, config.encryption.kafka.encryptionEnabled, config.kafkaTimeout);

export function createClient() {
	return kafkaProducer;
}

export function getClient() {
	return kafkaProducer;
}

export function send(topic, messages, sendPlaintext, partitionKey) {
	return kafkaProducer.send(topic, messages, sendPlaintext, partitionKey);
}