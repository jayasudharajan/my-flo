package com.flo.communication

import java.util.Properties
import java.util.concurrent.TimeUnit

import org.apache.kafka.clients.producer.{ProducerRecord, RecordMetadata, KafkaProducer => KProducer}

import scala.concurrent.{ExecutionContext, Future, blocking}

class AsyncKafkaProducer(kafkaHost: String, timeoutInSeconds: Int = 5)(implicit ec: ExecutionContext) {
  private val serializer = "org.apache.kafka.common.serialization.StringSerializer"

  private val configuration: Properties = {
    val props = new Properties()
    props.put("bootstrap.servers", kafkaHost)
    props.put("key.serializer", serializer)
    props.put("value.serializer", serializer)
    props
  }

  val producer = new KProducer[String, String](configuration)

  def send[T](topic: String, message: T, serialize: T => String): Future[RecordMetadata] = {
    val serializedMessage = serialize(message)
    val data = new ProducerRecord[String, String](topic, serializedMessage)

    Future {
      blocking {
        producer.send(data).get(timeoutInSeconds, TimeUnit.SECONDS)
      }
    }
  }

  def close(): Future[Unit] = {
    Future {
      blocking {
        producer.close(timeoutInSeconds, TimeUnit.SECONDS)
      }
    }
  }
}
