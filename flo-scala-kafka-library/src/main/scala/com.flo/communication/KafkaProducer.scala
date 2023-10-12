package com.flo.communication

import java.util.Properties
import java.util.concurrent.TimeUnit

import org.apache.kafka.clients.producer.{ProducerRecord, RecordMetadata, KafkaProducer => KProducer}

class KafkaProducer(kafkaHost: String,
                    topic: String,
                    brokers: Int = 1,
                    messageEncoder: Option[(String) => String] = None,
                    enableIdempotence: Boolean = true,
                    deliveryTimeoutInMs: Long = 120000,
                    retries: Int = Int.MaxValue
                   ) extends IKafkaProducer {

  private val serializer = "org.apache.kafka.common.serialization.StringSerializer"

  private def configuration: Properties = {
    val props = new Properties()
    props.put("bootstrap.servers", kafkaHost)
    props.put("key.serializer", serializer)
    props.put("value.serializer", serializer)
    props.put("enable.idempotence", enableIdempotence.toString)
    props.put("delivery.timeout.ms", deliveryTimeoutInMs.toString)
    props.put("retries", retries.toString)
    //props.put("batch.size", 10000)
    //props.put("linger.ms", 10)
    //props.put("buffer.memory", 33554432)

    props
  }

  def send[T <: AnyRef](message: T, serializer: T => String): RecordMetadata = {
    val producer = new KProducer[String, String](configuration)
    val serializedMessage = serialize[T](message, serializer)
    val data = new ProducerRecord[String, String](topic, serializedMessage)

    val recordMetadata = producer.send(data).get(10, TimeUnit.SECONDS)
    producer.close()

    recordMetadata
  }

  protected def serialize[T <: AnyRef](message: T, serializer: T => String): String = {
    val serialized = serializer(message)

    messageEncoder match {
      case Some(f) => f(serialized)
      case None => serialized
    }
  }
}