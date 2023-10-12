package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.{ConsumerMessage, ProducerMessage, ProducerSettings}
import akka.stream.ActorMaterializer
import com.flo.communication.utils.IKafkaConsumerMetrics
import com.ovoenergy.kafka.serialization.avro4s.avroBinarySchemaIdSerializer
import com.ovoenergy.kafka.serialization.core.{Format, formatSerializer}
import com.sksamuel.avro4s._
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringSerializer

import scala.concurrent.ExecutionContext

class ProducerWithSchemaRegistryHelper[VProducer <: Product : ToRecord : SchemaFor](
                                                                                  val clientName: String,
                                                                                  val bootstrapServers: String,
                                                                                  val groupId: String,
                                                                                  schemaRegistryUrl: String
                                                                                )(
                                                                                  implicit system: ActorSystem,
                                                                                  ec: ExecutionContext,
                                                                                  materializer: ActorMaterializer,
                                                                                  metrics: IKafkaConsumerMetrics
                                                                                ) extends AvroProducerHelper[VProducer, VProducer] {



  override def getProducerSettings(): ProducerSettings[String, VProducer] = {
    //implicit val toRecord = ToRecord[VProducer]

    val serializer = avroBinarySchemaIdSerializer[VProducer](
      schemaRegistryUrl, isKey = false, includesFormatByte = false
    )

    ProducerSettings(system, new StringSerializer, formatSerializer(Format.AvroBinarySchemaId, serializer))
  }

  override def createProducerMessage(destinationTopic: String, msg: DeserializedMessage[VProducer]): ProducerMessage = {
    ProducerMessage.Message[String, VProducer, ConsumerMessage.CommittableOffset](
      new ProducerRecord(destinationTopic, msg.item),
      msg.offset
    )
  }
}
