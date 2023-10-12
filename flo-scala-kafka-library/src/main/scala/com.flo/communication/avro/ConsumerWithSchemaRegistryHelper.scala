package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.ConsumerSettings
import akka.stream.ActorMaterializer
import com.flo.communication.utils.IKafkaConsumerMetrics
import com.sksamuel.avro4s._
import org.apache.kafka.common.serialization.{Deserializer, StringDeserializer}
import scala.concurrent.ExecutionContext

class ConsumerWithSchemaRegistryHelper[VConsumer <: Product : Decoder : SchemaFor](
                          val clientName: String,
                          val bootstrapServers: String,
                          val groupId: String,
                          schemaRegistryUrl: String
                        )(
                          implicit system: ActorSystem,
                          ec: ExecutionContext,
                          materializer: ActorMaterializer,
                          metrics: IKafkaConsumerMetrics
                        ) extends AvroConsumerHelper[VConsumer, VConsumer] {

  private val serializer = new AvroSerializer
  implicit val schema = AvroSchema[VConsumer]

  override def getConsumerSettings(): ConsumerSettings[String, VConsumer] = {
    //TODO: Using Avro4s with Confluent Kafka Avro Serializer + Schema Registry
    //https://gist.github.com/kdrakon/618f1312f2b96d469492568f8d56e036

    //TODO: this https://github.com/sksamuel/avro4s/issues/280 was no released for 2.11 so the other helper library neither was

    //val deserializer = avroBinarySchemaIdDeserializer[VConsumer](
    //  schemaRegistryUrl, isKey = false, includesFormatByte = true
    //)

    //This is used because the library that helps on schema registry has not updated the avro4s dependency
    //to the one that support schema field ciustomization that is needed due to KSQL uppercase behaviour
    val workaroundDeserializer = new Deserializer[VConsumer] {
      def configure(configs: java.util.Map[String, _], isKey: Boolean): Unit = {
        //deserializer.configure(configs, false)
      }

      def deserialize(topic: String, data: Array[Byte]): VConsumer = {
        serializer.deserialize[VConsumer](data.slice(5, data.length)).head
      }

      override def close(): Unit = {
        //deserializer.close()
      }
    }

    ConsumerSettings(system, new StringDeserializer, workaroundDeserializer)
  }

  def deserialize(value: VConsumer): List[VConsumer] = {
    List(value)
  }
}
