package com.flo.communication.avro

import akka.kafka.scaladsl.Consumer
import akka.stream.scaladsl.Source
import com.flo.communication.TopicRecord
import com.sksamuel.avro4s._

trait IAvroWithSchemaRegistryKafkaConsumer {
  def consume[T <: Product : Decoder : FromRecord : SchemaFor](
                                                                topic: String,
                                                                processor: TopicRecord[T] => Unit
                                                              ): Unit

  def forwardTo[TSource <: Product : Decoder : FromRecord : SchemaFor, TDestination <: Product : Encoder : ToRecord : SchemaFor](
                                                                                                                                  sourceTopic: String,
                                                                                                                                  destinationTopic: String,
                                                                                                                                  mapper: Source[DeserializedMessage[TSource], Consumer.Control] => Source[DeserializedMessage[TDestination], Consumer.Control]
                                                                                                                                ): Unit
}
