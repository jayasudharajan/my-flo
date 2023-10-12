package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.{ConsumerMessage, ProducerMessage, ProducerSettings}
import com.sksamuel.avro4s.{Encoder, SchemaFor}
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.{ByteArraySerializer, StringSerializer}

class ProducerStandardAvroHelper[ToSerialize <: Product : Encoder : SchemaFor](
                                                                                val clientName: String,
                                                                                val bootstrapServers: String,
                                                                                val groupId: String
                                                                              )(implicit system: ActorSystem) extends AvroProducerHelper[ToSerialize, Array[Byte]] {

  override def getProducerSettings(): ProducerSettings[String, Array[Byte]] = {
    ProducerSettings(system, new StringSerializer, new ByteArraySerializer)
  }

  override def createProducerMessage(destinationTopic: String, msg: DeserializedMessage[ToSerialize]): ProducerMessage = {
    ProducerMessage.Message[String, Array[Byte], ConsumerMessage.CommittableOffset](
      new ProducerRecord(destinationTopic, serializer.serialize[ToSerialize](msg.item)),
      msg.offset
    )
  }
}
