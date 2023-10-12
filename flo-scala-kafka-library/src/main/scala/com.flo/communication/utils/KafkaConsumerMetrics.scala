package com.flo.communication.utils

import kamon.metric.instrument.InstrumentFactory
import kamon.metric.{EntityRecorderFactory, GenericEntityRecorder}


class KafkaConsumerMetrics(instrumentFactory: InstrumentFactory)
  extends GenericEntityRecorder(instrumentFactory) with IKafkaConsumerMetrics {

  private val deserializationErrors = counter("deserialization-errors")
  private val processorErrors = counter("processor-errors")
  private val successfullyConsumed = counter("successfully-consumed")
  private val totalConsumed = counter("total-consumed")

  def newDeserializationError(): Unit = {
    deserializationErrors.increment()
    totalConsumed.increment()
  }

  def newProcessorError(): Unit = {
    processorErrors.increment()
    totalConsumed.increment()
  }

  def newSuccess(): Unit = {
    successfullyConsumed.increment()
    totalConsumed.increment()
  }
}

object KafkaConsumerMetrics extends EntityRecorderFactory[KafkaConsumerMetrics] {
  def category: String = "kafka-consumer"
  def createRecorder(instrumentFactory: InstrumentFactory): KafkaConsumerMetrics =
    new KafkaConsumerMetrics(instrumentFactory)
}