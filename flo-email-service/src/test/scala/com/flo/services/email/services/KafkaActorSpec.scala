package com.flo.services.email.services

import akka.actor.{ActorSystem, Props}
import akka.testkit.{ImplicitSender, TestActorRef, TestKit, TestProbe}
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.utils.FromSneakToCamelCaseDeserializer
import org.joda.time.DateTime
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}

class KafkaActorSpec extends TestKit(ActorSystem("KafkaActorSpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll {

  val deserializer = new FromSneakToCamelCaseDeserializer

  val kafkaConsumer: IKafkaConsumer = new IKafkaConsumer {

      def shutdown(): Unit = {}

      override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
        List(TopicRecord(KafkaTestMessage(), DateTime.now())).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
          processor(x)
        }
      }

      override def pause(): Unit = ???

      override def resume(): Unit = ???

      override def isPaused(): Boolean = false
    }

  case class KafkaTestMessage()

  class TestKafkaActorConsumer
    extends KafkaActorConsumer[KafkaTestMessage](kafkaConsumer, x => deserializer.deserialize[KafkaTestMessage](x), 100000) {

    override def consume(message: KafkaTestMessage): Unit = {
      TestKafkaActorConsumer.consumeActionCalled = true
    }
  }

  object TestKafkaActorConsumer {
    var consumeActionCalled = false
  }

  override def afterAll(): Unit = {
    TestKit.shutdownActorSystem(system)
  }

  "The TestKafkaActor" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()

      TestActorRef(
        Props(new TestKafkaActorConsumer),
        parent.ref,
        "TestKafkaActor"
      )

      awaitAssert(TestKafkaActorConsumer.consumeActionCalled shouldEqual true)
    }
  }
}