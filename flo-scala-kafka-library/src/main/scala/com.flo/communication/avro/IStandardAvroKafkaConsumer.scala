package com.flo.communication.avro

import akka.kafka.scaladsl.Consumer
import akka.stream.scaladsl.Source
import com.flo.communication.TopicRecord
import com.sksamuel.avro4s.{Decoder, Encoder, SchemaFor}

trait IStandardAvroKafkaConsumer {
  def consume[T <: Product : Decoder : SchemaFor](
                                                   topic: String,
                                                   processor: TopicRecord[T] => Unit
                                                 ): Unit

  def forwardTo[TSource <: Product : Decoder : SchemaFor, TDestination <: Product : Encoder : SchemaFor](
                                                                                                          sourceTopic: String,
                                                                                                          destinationTopic: String,
                                                                                                          mapper: Source[DeserializedMessage[TSource], Consumer.Control] => Source[DeserializedMessage[TDestination], Consumer.Control]
                                                                                                        ): Unit
}
