package com.flo.task.scheduler.services.commands

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.Models.KafkaMessages.SchedulerCommand
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.task.scheduler.services.BaseActorsSpec
import com.flo.utils.FromSneakToCamelCaseDeserializer
import org.joda.time.DateTime

import scala.concurrent.duration._

class CommandConsumerSpec extends BaseActorsSpec {

  val deserializer = new FromSneakToCamelCaseDeserializer

  val kafkaConsumer: IKafkaConsumer =
    new IKafkaConsumer {

      def shutdown(): Unit = {}

      override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
        List(
          TopicRecord(command2, DateTime.now()),
          TopicRecord(command1, DateTime.now())
        ).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
          processor(x)
        }
      }

      override def pause(): Unit = ???

      override def resume(): Unit = ???

      override def isPaused(): Boolean = false
    }

  "The CommandConsumer" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()

      val schedulerInstanceHandler = getInstanceHandler(false)

      val commandKafkaConsumerProps = CommandsConsumer.props(
        kafkaConsumer,
        x => deserializer.deserialize[SchedulerCommand](x),
        schedulerInstanceHandler,
        taskEndpoints,
        300
      )

      TestActorRef(
        commandKafkaConsumerProps,
        parent.ref,
        "CommandKafkaConsumer"
      )

      awaitAssert({
        schedulerInstanceHandler.getReal().getCommands should contain only (executorCommand1, executorCommand2)
      }, 4.second, 100.milliseconds)
    }
  }
}