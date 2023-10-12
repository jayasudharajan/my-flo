import { Kafka } from 'kafkajs';
import _ from 'lodash';
import config from '../config';
import { processMessage } from '../entity-activity/processMessage';
import { TopicOffset } from '../interfaces';

const kafka = new Kafka({
  clientId: config.kafkaGroupId,
  brokers: config.kafkaBrokerList.split(','),
  connectionTimeout: config.kafkaConnectionTimeoutInMs
})
const kafkaConsumer = kafka.consumer({ groupId: config.kafkaGroupId });

const maxExecutionTimeOrTopicEmpty = async (startTime: [number, number]) => new Promise(async (resolve, reject) => {
  const admin = kafka.admin();
  await admin.connect();

  const timeout = setInterval(async () => {
    try {
      if (process.hrtime(startTime)[0] >= config.maxExecutionTimeInSeconds) {
        console.log(`Max execution time reached: ${config.maxExecutionTimeInSeconds} seconds.`)
        disconnectAndStop();
        return resolve();
      }

      const eventualOffsets: Promise<Array<TopicOffset>> = admin.fetchTopicOffsets(config.kafkaTopic);
      const eventualOffsetsByGroupId: Promise<Array<TopicOffset>> = admin.fetchOffsets({ groupId: config.kafkaGroupId, topic: config.kafkaTopic });
      const [offsets, offsetsByGroupId] = await Promise.all([ eventualOffsets, eventualOffsetsByGroupId ]);

      const groupedOffsets = _.groupBy(offsets.concat(offsetsByGroupId), 'partition');

      console.log(`Retrieved offsets: ${JSON.stringify(groupedOffsets)}`);

      const topicEmpty = _.every(groupedOffsets, (partitionOffsets) => {
        return partitionOffsets.length === 2 &&
          partitionOffsets[0].offset !== '-1' && partitionOffsets[1].offset !== '-1' &&
          partitionOffsets[0].offset === partitionOffsets[1].offset;
      })

      if (topicEmpty) {
        console.log(`No remaining messages to be read from Topic ${config.kafkaTopic}.`);
        disconnectAndStop();
        return resolve();
      }
    } catch (e) {
      console.error(e);
      disconnectAndStop();
      return reject(e);
    }
  }, config.topicEmptyCheckLoopIntervalInMs);

  const disconnectAndStop = () => {
    admin.disconnect();
    clearInterval(timeout);
  }
});

export const handleEvent = async (): Promise<void> => {
  const startTime = process.hrtime();

  console.log(`Connecting to Kafka: ${config.kafkaBrokerList}`);
  await kafkaConsumer.connect();

  console.log(`Subscribing to Topic ${config.kafkaTopic}`);
  await kafkaConsumer.subscribe({ topic: config.kafkaTopic });

  const run = async () => kafkaConsumer.run({
    eachBatchAutoResolve: false,
    eachBatch: async ({ batch, resolveOffset, heartbeat, isRunning, isStale }) => {
      for (const message of batch.messages) {

        if (!isRunning() || isStale()) break;

        const strMessage = message.value.toString();
        console.log(`Processing message ${strMessage}`);
        await processMessage(JSON.parse(strMessage));

        resolveOffset(message.offset);
        await heartbeat();
      }
    }
  });

  run();

  await maxExecutionTimeOrTopicEmpty(startTime);
  await kafkaConsumer.disconnect();
};