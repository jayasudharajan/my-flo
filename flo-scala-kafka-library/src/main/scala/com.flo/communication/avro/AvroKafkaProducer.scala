package com.flo.communication.avro

import java.util.Properties
import java.util.concurrent.TimeUnit

import org.apache.kafka.clients.producer.{ProducerRecord, RecordMetadata, KafkaProducer => KProducer}

class AvroKafkaProducer(kafkaHost: String,
                    topic: String,
                    brokers: Int = 1
                   ) {

  private def configuration: Properties = {
    val props = new Properties()
    props.put("bootstrap.servers", kafkaHost)
    props.put("key.serializer",  "org.apache.kafka.common.serialization.StringSerializer")
    props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer")
    props
  }

  def send(bytes: Array[Byte]): RecordMetadata = {
    val producer = new KProducer[String, Array[Byte]](configuration)
    val data = new ProducerRecord[String, Array[Byte]](topic, bytes)

    val recordMetadata = producer.send(data).get(10, TimeUnit.SECONDS)
    producer.close()

    recordMetadata
  }
}