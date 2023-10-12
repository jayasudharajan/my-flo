package com.flo.communication.avro

import akka.actor.ActorSystem
import akka.kafka.scaladsl.Consumer
import akka.stream.ActorMaterializer
import akka.stream.scaladsl.Source
import com.flo.communication.TopicRecord
import com.flo.communication.utils.IKafkaConsumerMetrics
import com.sksamuel.avro4s._

class StandardAvroKafkaConsumer(
                         val clientName: String,
                         val bootstrapServers: String,
                         val groupId: String
                       )(
  implicit val system: ActorSystem,
  val materializer: ActorMaterializer,
  val metrics: IKafkaConsumerMetrics
) extends IAvroKafkaConsumer with IStandardAvroKafkaConsumer {

  def consume[T <: Product : Decoder : SchemaFor](
                                                    topic: String,
                                                    processor: TopicRecord[T] => Unit
                                                  ): Unit = {
    super.consume[Array[Byte], T](
      topic,
      processor,
      new ConsumerStandardAvroHelper[T](
        clientName,
        bootstrapServers,
        groupId
      )
    )
  }

  def forwardTo[TSource <: Product : Decoder : SchemaFor, TDestination <: Product : Encoder : SchemaFor](
                                                            sourceTopic: String,
                                                            destinationTopic: String,
                                                            mapper: Source[DeserializedMessage[TSource], Consumer.Control] => Source[DeserializedMessage[TDestination], Consumer.Control]
                                                          ): Unit = {
    super.forwardTo[Array[Byte], Array[Byte], TSource, TDestination](
      sourceTopic,
      destinationTopic,
      mapper,
      new ConsumerStandardAvroHelper[TSource](
        clientName,
        bootstrapServers,
        groupId
      ),
      new ProducerStandardAvroHelper[TDestination](
        clientName,
        bootstrapServers,
        groupId
      )
    )
  }
}

