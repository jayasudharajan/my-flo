package com.flo.communication

import org.apache.kafka.clients.producer.RecordMetadata

trait IKafkaProducer {
  def send[T <: AnyRef](message: T, serializer: T => String): RecordMetadata
}
