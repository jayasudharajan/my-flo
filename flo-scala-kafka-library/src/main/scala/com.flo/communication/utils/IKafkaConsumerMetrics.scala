package com.flo.communication.utils

trait IKafkaConsumerMetrics {
  def newDeserializationError(): Unit
  def newProcessorError(): Unit
  def newSuccess(): Unit
}



