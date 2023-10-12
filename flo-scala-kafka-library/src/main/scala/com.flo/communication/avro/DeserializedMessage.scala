package com.flo.communication.avro

import akka.kafka.ConsumerMessage

case class DeserializedMessage[T](
                                                   item: T,
                                                   timestamp: Long,
                                                   offset: ConsumerMessage.CommittableOffset
                                                 ) extends Message

case class ErrorMessage(
                         timestamp: Long,
                         offset: ConsumerMessage.CommittableOffset
                       )

trait Message {
  val offset: ConsumerMessage.CommittableOffset
}
