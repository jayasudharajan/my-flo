package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.scaladsl.Consumer
import akka.stream.ActorMaterializer
import akka.stream.scaladsl.Source
import com.flo.communication.TopicRecord
import com.flo.communication.utils.IKafkaConsumerMetrics
import com.sksamuel.avro4s._

class AvroWithSchemaRegistryKafkaConsumer(
                                           val clientName: String,
                                           val bootstrapServers: String,
                                           val groupId: String,
                                           schemaRegistryUrl: String
                                         )(
                                           implicit val system: ActorSystem,
                                           val materializer: ActorMaterializer,
                                           val metrics: IKafkaConsumerMetrics
                                         ) extends IAvroKafkaConsumer with IAvroWithSchemaRegistryKafkaConsumer {

  import system.dispatcher

  def consume[T <: Product : Decoder : FromRecord : SchemaFor](
                                          topic: String,
                                          processor: TopicRecord[T] => Unit
                                        ): Unit = {
    super.consume[T, T](
      topic,
      processor,
      new ConsumerWithSchemaRegistryHelper[T](
        clientName,
        bootstrapServers,
        groupId,
        schemaRegistryUrl
      )
    )
  }

  def forwardTo[TSource <: Product : Decoder : FromRecord : SchemaFor, TDestination <: Product : Encoder : ToRecord : SchemaFor](
                                                                                sourceTopic: String,
                                                                                destinationTopic: String,
                                                                                mapper: Source[DeserializedMessage[TSource], Consumer.Control] => Source[DeserializedMessage[TDestination], Consumer.Control]
                                                                              ): Unit = {
    super.forwardTo[TSource, TDestination, TSource, TDestination](
      sourceTopic,
      destinationTopic,
      mapper,
      new ConsumerWithSchemaRegistryHelper[TSource](
        clientName,
        bootstrapServers,
        groupId,
        schemaRegistryUrl
      ),
      new ProducerWithSchemaRegistryHelper[TDestination](
        clientName,
        bootstrapServers,
        groupId,
        schemaRegistryUrl
      )
    )
  }
}