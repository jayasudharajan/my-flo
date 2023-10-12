package com.flo.notification.kafka

import akka.kafka.ProducerSettings
import akka.kafka.scaladsl.Producer
import akka.stream.ActorMaterializer
import akka.stream.scaladsl.Source
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.delivery.KafkaSender
import org.apache.kafka.clients.producer.{ProducerRecord, Producer => KafkaProducer}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

class SendToKafka(producerSettings: ProducerSettings[String, String], producer: KafkaProducer[String, String])(
    implicit ec: ExecutionContext,
    am: ActorMaterializer
) extends KafkaSender {

  import SendToKafka.log

  private val sink = Producer.plainSink(producerSettings, producer)

  def apply(topic: String, message: String): Future[Unit] = {
    log.debug(p"Sending message to Kafka. Topic = $topic, Message = $message")
    val eventuallySentMsg = Source
      .single(message)
      .map(value => new ProducerRecord[String, String](topic, value))
      .runWith(sink)

    eventuallySentMsg.onComplete {
      case Success(_) => log.debug(p"Successfully sent message to Kafka. Topic = $topic, Message = $message")
      case Failure(e) => log.error(p"Error while sending message to Kafka. Topic = $topic, Message = $message", e)
    }

    // Do not fail when sending message to Kafka. Underlying Kafka Producer should handle retries.
    Future.unit
  }
}

private object SendToKafka {
  private val log = logbookFor(getClass)
}
