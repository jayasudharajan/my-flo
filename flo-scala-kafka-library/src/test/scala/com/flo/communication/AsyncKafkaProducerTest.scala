package com.flo.communication

import net.manub.embeddedkafka.{EmbeddedKafka, EmbeddedKafkaConfig}
import org.apache.kafka.common.serialization.StringDeserializer
import org.scalatest.WordSpec

import scala.concurrent.ExecutionContext.Implicits.global
import org.scalatest.concurrent.ScalaFutures
import org.scalatest.time.{Millis, Seconds, Span}

import scala.util.Random

class AsyncKafkaProducerTest extends WordSpec with EmbeddedKafka with ScalaFutures {

  implicit val defaultPatience = PatienceConfig(timeout = Span(2, Seconds), interval = Span(5, Millis))

  case class MessageData(a: String, b: String)

  "AsyncKafkaProducer" should {
    "send data to Kafka" in {
      implicit val embeddedKafkaConfig = EmbeddedKafkaConfig(9200 + Random.nextInt(500), 2188 + Random.nextInt(500))
      implicit val kafkaDeserializer = new StringDeserializer

      val kafkaHost = s"localhost:${embeddedKafkaConfig.kafkaPort}"
      val topic1 = "async-kafka-producer-test-1"
      val topic2 = "async-kafka-producer-test-2"

      withRunningKafka {
        val asyncKafkaProducer = new AsyncKafkaProducer(kafkaHost)

        whenReady {
          asyncKafkaProducer.send[MessageData](topic1, MessageData("Hello1", "World1"), x => s"""{\"a\":\"${x.a}\",\"b\":\"${x.b}\"}""")
        } { _ =>
          val msg = consumeFirstMessageFrom(topic1)
          assert("{\"a\":\"Hello1\",\"b\":\"World1\"}" == msg)
        }

        whenReady {
          asyncKafkaProducer.send[MessageData](topic2, MessageData("Hello2", "World2"), x => s"""{\"a\":\"${x.a}\",\"b\":\"${x.b}\"}""")
        } { _ =>
          val msg = consumeFirstMessageFrom(topic2)
          assert("{\"a\":\"Hello2\",\"b\":\"World2\"}" == msg)
        }
      }
    }
  }
}
