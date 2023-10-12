package com.flo.puck.kafka

import java.time.Duration

package object conf {

  private[kafka] case class KafkaConfig(
    hosts: String,
    puckTelemetryConsumer: ConsumerConfig,
    entityActivityConsumer: ConsumerConfig,
    alertStatusProducer: ProducerConfig,
  )
  private[kafka] case class ConsumerConfig(groupId: String, topic: String, pollTimeout: Duration, parallelism: Int)
  private[kafka] case class ProducerConfig(topic: String)
}
