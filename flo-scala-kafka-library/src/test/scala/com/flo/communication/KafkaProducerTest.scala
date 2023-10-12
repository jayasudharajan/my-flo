package com.flo.communication

import net.manub.embeddedkafka.{EmbeddedKafka, EmbeddedKafkaConfig}
import org.apache.kafka.common.serialization.StringDeserializer
import org.scalatest.WordSpec

import scala.util.Random

class KafkaProducerTest extends WordSpec with EmbeddedKafka {

  private val topic = "kafka-producer-test"

  case class MessageData(a: String, b: String)

  "The KafkaProducer" should {
    "send data to kafka and is received" in {
      implicit val embeddedKafkaConfig = EmbeddedKafkaConfig(9200 + Random.nextInt(500), 2188 + Random.nextInt(500))
      implicit val kafkaDeserializer = new StringDeserializer
      val kafkaHost = s"localhost:${embeddedKafkaConfig.kafkaPort}"

      withRunningKafka {

        //Send data to Kafka
        val kafkaApi = new KafkaProducer(kafkaHost, topic)
        kafkaApi.send[MessageData](new MessageData("Hello", "World"), x => s"""{\"a\":\"${x.a}\",\"b\":\"${x.b}\"}""")

        val msg = consumeFirstMessageFrom(topic)
        assert("{\"a\":\"Hello\",\"b\":\"World\"}" == msg)
      }
    }
  }
}