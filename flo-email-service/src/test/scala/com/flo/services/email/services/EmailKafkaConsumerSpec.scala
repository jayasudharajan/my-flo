package com.flo.services.email.services

import akka.testkit.{TestActorRef, TestProbe}
import argonaut.Parse
import com.flo.Models.KafkaMessages.EmailMessage
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import org.joda.time.DateTime

class EmailKafkaConsumerSpec extends BaseEmailActorsSpec {

  val kafkaConsumer: IKafkaConsumer = new IKafkaConsumer {

    def shutdown(): Unit = {}

    override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
      List(
        TopicRecord(email1, DateTime.now()),
        TopicRecord(email2, DateTime.now())
      ).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
        processor(x)
      }
    }

    override def pause(): Unit = ???

    override def resume(): Unit = ???

    override def isPaused(): Boolean = false
  }

  "The EmailKafkaConsumerSpec" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()
      val emailClient = emailClientThatSuccess

      val telemetryConsumerProps = EmailKafkaConsumer.props(
          kafkaConsumer,
          (x: String) => Parse.decodeOption[EmailMessage](x).get,
          emailClient,
          100000
      )

      TestActorRef(
        telemetryConsumerProps,
        parent.ref,
        "EmailKafkaConsumer"
      )

      awaitAssert(
        emailClient.getSavedData should contain only (
          EmailTransformations.toActorEmailMessage(email1),
          EmailTransformations.toActorEmailMessage(email2)
        )
      )
    }
  }
}