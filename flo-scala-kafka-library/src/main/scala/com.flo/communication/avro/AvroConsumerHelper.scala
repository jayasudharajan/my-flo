package com.flo.communication.avro

import akka.kafka.ConsumerSettings
import org.apache.kafka.clients.consumer.ConsumerConfig

trait AvroConsumerHelper[V, Deserialized] extends AvroHelper {
  protected def getConsumerSettings(): ConsumerSettings[String, V]

  val consumerSettings = getConsumerSettings()
    .withBootstrapServers(bootstrapServers)
    .withGroupId(groupId)
    .withProperty(ConsumerConfig.CLIENT_ID_CONFIG, getClientId(clientName))
    .withProperty(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest")


  def deserialize(value: V): List[Deserialized]
}
