package com.flo.router.telemetry.services

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.router.telemetry.domain.Telemetry
import com.flo.utils.FromSneakToCamelCaseDeserializer
import org.joda.time.DateTime

class TelemetryKafkaConsumerSpec extends BaseTelemetryActorsSpec {

  val deserializer = new FromSneakToCamelCaseDeserializer

  val kafkaConsumer: IKafkaConsumer =
    new IKafkaConsumer {

      def shutdown(): Unit = {}

      override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
        List(
          TopicRecord(telemetry1, DateTime.now()),
          TopicRecord(telemetry2, DateTime.now())
        ).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
          processor(x)
        }
      }

      override def pause(): Unit = ???

      override def resume(): Unit = ???

      override def isPaused(): Boolean = false
    }

  "The TelemetryKafkaConsumer" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()

      val goodDataTelemetryRepository = repositoryThatSuccess
      val badDataTelemetryRepository = repositoryThatSuccess

      val telemetryConsumerProps = TelemetryKafkaConsumer.props(
        TelemetryKafkaConsumer.TelemetryKafkaConsumerSettings(
          kafkaConsumer,
          //avroKafkaConsumer,
          "avro-topic",
          x => deserializer.deserialize[Telemetry](x),
          goodDataTelemetryRepository,
          badDataTelemetryRepository,
          300
        )
      )

      TestActorRef(
        telemetryConsumerProps,
        parent.ref,
        "TelemetryKafkaConsumer"
      )

      awaitAssert(goodDataTelemetryRepository.getSavedData should contain only (telemetry1, telemetry2))
    }
  }
}