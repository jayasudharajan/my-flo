package com.flo.communication.avro

import akka.kafka.{ConsumerMessage, ProducerMessage, ProducerSettings}

trait AvroProducerHelper[ToSerialize, V] extends AvroHelper {
  type ProducerMessage = ProducerMessage.Message[String, V, ConsumerMessage.CommittableOffset]

  val serializer = new AvroSerializer

  protected def getProducerSettings(): ProducerSettings[String, V]

  val producerSettings = getProducerSettings()
    .withBootstrapServers(bootstrapServers)

  def createProducerMessage(destinationTopic: String, msg: DeserializedMessage[ToSerialize]): ProducerMessage
}