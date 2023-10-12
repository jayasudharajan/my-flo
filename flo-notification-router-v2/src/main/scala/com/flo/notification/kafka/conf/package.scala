package com.flo.notification.kafka

import java.time.Duration

package object conf {

  private[kafka] case class KafkaConfig(hosts: String,
                                        alarmIncidentConsumer: ConsumerConfig,
                                        alertStatusConsumer: ConsumerConfig,
                                        entityActivityConsumer: ConsumerConfig)

  private[kafka] case class ConsumerConfig(groupId: String, topic: String, pollTimeout: Duration, parallelism: Int)
}
