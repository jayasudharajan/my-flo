package com.flo.communication

import net.manub.embeddedkafka.{EmbeddedKafka, EmbeddedKafkaConfig}
import org.apache.kafka.common.serialization.{StringDeserializer}
import org.scalatest.WordSpec
import scala.util.Random

class EncryptedKafkaProducerTest extends WordSpec with EmbeddedKafka with EncryptionTestUtils {

  private val topic = "kafka-producer-test"

  case class MessageData(a: String, b: String)

  "The EncryptedKafkaProducer" should {
    "send encrypted data to kafka and is received" in {
      implicit val embeddedKafkaConfig = EmbeddedKafkaConfig(9200 + Random.nextInt(500), 2188 + Random.nextInt(500))
      implicit val kafkaDeserializer = new StringDeserializer
      val kafkaHost = s"localhost:${embeddedKafkaConfig.kafkaPort}"

      withRunningKafka {

        //Send data to Kafka
        val kafkaApi = new KafkaProducer(
          kafkaHost,
          topic,
          messageEncoder = Some((m: String) => encrypt(m)))
        kafkaApi.send[MessageData](new MessageData("Hello", "World"), x => s"""{\"a\":\"${x.a}\",\"b\":\"${x.b}\"}""")

        //Create consumer
        val msg = decrypt(consumeFirstMessageFrom(topic))

        assert("{\"a\":\"Hello\",\"b\":\"World\"}" == msg)
      }
    }
  }
}