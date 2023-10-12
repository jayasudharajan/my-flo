package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.ConsumerSettings
import com.sksamuel.avro4s._
import org.apache.kafka.common.serialization.{ByteArrayDeserializer, StringDeserializer}

class ConsumerStandardAvroHelper[Deserialized <: Product : Decoder : SchemaFor](
                          val clientName: String,
                          val bootstrapServers: String,
                          val groupId: String
                        )(implicit system: ActorSystem) extends AvroConsumerHelper[Array[Byte], Deserialized] {

  val serializer = new AvroSerializer

  override def getConsumerSettings(): ConsumerSettings[String, Array[Byte]] = {
    ConsumerSettings(system, new StringDeserializer, new ByteArrayDeserializer)
      .asInstanceOf[ConsumerSettings[String, Array[Byte]]]
  }

  override def deserialize(value: Array[Byte]): List[Deserialized] = {
    serializer.deserialize[Deserialized](value)
  }
}
