import { ScheduledEvent } from 'aws-lambda';
import Kafka from 'no-kafka';
import scrollThruDevices from '../api-v1/scrollThruDevices';
import config from '../config';
import { enableMttcForDevices } from '../mttc/mttcEnabler';

const kafkaProducer = new Kafka.Producer({
  connectionString: config.kafkaBrokerList,
  timeout: parseInt(config.kafkaTimeout),
  connectionTimeout: parseInt(config.kafkaConnectTimeout),
  socketTimeout: parseInt(config.kafkaSocketTimeout)
});

export const handleEvent = async (_event: ScheduledEvent): Promise<void> => {
  try {
    console.log(`Initializing Kafka Producer => ${config.kafkaBrokerList}`);
    await kafkaProducer.init();

    console.log('Retrieving and scrolling through Devices.');
    await scrollThruDevices(devices => enableMttcForDevices(kafkaProducer, devices));

    console.log('Closing Kafka Producer.');
    await kafkaProducer.end();
  } catch (err) {
    console.error(`Error while handling event => ${err}`);
  }
};