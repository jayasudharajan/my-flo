package com.flo.task.scheduler.services.tasks

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.Models.KafkaMessages.Task
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.task.scheduler.services.BaseActorsSpec
import com.flo.utils.FromSneakToCamelCaseDeserializer
import org.joda.time.DateTime

import scala.concurrent.duration._

class TasksConsumerSpec extends BaseActorsSpec {

  val deserializer = new FromSneakToCamelCaseDeserializer

  val kafkaConsumer: IKafkaConsumer =
    new IKafkaConsumer {

      def shutdown(): Unit = {}

      override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
        List(
          TopicRecord(task1, DateTime.now()),
          TopicRecord(task2, DateTime.now())
        ).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
          processor(x)
        }
      }

      override def pause(): Unit = ???

      override def resume(): Unit = ???

      override def isPaused(): Boolean = false
    }


  "The TasksConsumer" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()

      val schedulerInstanceHandler = getInstanceHandler(false)
      val producerRepository = getKafkaProducerRepository

      val tasksConsumerProps = TasksConsumer.props(
        kafkaConsumer,
        producerRepository,
        x => deserializer.deserialize[Task](x),
        schedulerInstanceHandler,
        taskEndpoints,
        300
      )

      TestActorRef(
        tasksConsumerProps,
        parent.ref,
        "TasksConsumer"
      )

      awaitAssert({
        schedulerInstanceHandler.getReal().getTasks should contain only (task1, task2)
        producerRepository.producer.getMessages should contain only (task1.taskData, task2.taskData)
      }, 4.second, 100.milliseconds)
    }
  }
}