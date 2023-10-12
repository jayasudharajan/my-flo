/*
package com.flo.task.scheduler.services.tasks

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.Models.KafkaMessages.{Schedule, Task}
import com.flo.task.scheduler.utils._
import org.scalatest.{BeforeAndAfterEach, Matchers, WordSpec}
import redis.embedded.RedisServer
import org.scalatest.concurrent.Eventually._
import org.scalatest.time.SpanSugar._

class TaskSchedulerSpec extends WordSpec with Matchers with BeforeAndAfterEach {

  val redisPort = 6381
  val redisHost = "localhost"
  var redisServer: Option[RedisServer] = None

  implicit val patienceConfig =
    PatienceConfig(timeout = scaled(10 seconds), interval = scaled(1 seconds))

  override def beforeEach(): Unit = {
    redisServer = Some(new RedisServer(redisPort))
    redisServer.map(_.start())
  }

  override def afterEach(): Unit = {
    redisServer.map(_.stop())
  }

  def getNewTask(): Task = Task(
    "onetopic",
    "data1",
    Schedule(
      java.util.UUID.randomUUID.toString,
      Some("weeklyReport"),
      /*"*/1 * * ? * *",
      "UTC",
      None,
      None
    ),
    None
  )

  def getScheduler(taskExecutor: Task => Unit): TaskScheduler = {
    implicit val system = ActorSystem("task-scheduler-system")
    implicit val materializer = ActorMaterializer()
    implicit val executionContext = system.dispatcher
    new TaskScheduler(system, redisHost, redisPort, taskExecutor, 5)
  }

  "The TaskScheduler" should {
    "schedule know if one task is already scheduled" in {
      val scheduler = getScheduler(x => {})
      val task = getNewTask

      scheduler.isScheduled(task) shouldEqual false

      scheduler.schedule(task)
      scheduler.shutdown()

      scheduler.isScheduled(task) shouldEqual true
    }

    "execute a scheduled task" in {
      var taskExecutionCount = 0
      val scheduler = getScheduler(x => taskExecutionCount = taskExecutionCount + 1)
      val task = getNewTask

      scheduler.schedule(task)

      eventually {
        taskExecutionCount should be > 1
      }

      scheduler.shutdown()
    }

    "cancel a running task" in {
      var taskExecutionCount = 0
      val scheduler = getScheduler(x => taskExecutionCount = taskExecutionCount + 1)
      val task = getNewTask

      scheduler.schedule(task)

      Thread.sleep(2000)

      val taskExecutionCountSnapshoot = taskExecutionCount
      scheduler.cancel(task)

      Thread.sleep(3000)

      scheduler.shutdown()

      taskExecutionCount should be > 1
      taskExecutionCountSnapshoot shouldEqual taskExecutionCount
    }

    "suspend a running task" in {
      var taskExecutionCount = 0
      val scheduler = getScheduler(x => taskExecutionCount = taskExecutionCount + 1)
      val task = getNewTask

      scheduler.schedule(task)

      Thread.sleep(2000)

      val taskExecutionCountSnapshoot = taskExecutionCount
      scheduler.suspend(task)

      Thread.sleep(3000)

      scheduler.shutdown()

      taskExecutionCount should be > 1
      taskExecutionCountSnapshoot shouldEqual taskExecutionCount
    }

    "suspend all running task" in {
      var task1ExecutionCount = 0
      var task2ExecutionCount = 0
      val task1 = getNewTask
      val task2 = getNewTask
      val scheduler = getScheduler { x =>
        if(x.schedule.id == task1.schedule.id) {
          task1ExecutionCount = task1ExecutionCount + 1
        }
        if(x.schedule.id == task2.schedule.id) {
          task2ExecutionCount = task2ExecutionCount + 1
        }
      }

      scheduler.schedule(task1)
      scheduler.schedule(task2)

      Thread.sleep(2000)

      val task1ExecutionCountSnapshoot = task1ExecutionCount
      val task2ExecutionCountSnapshoot = task2ExecutionCount
      scheduler.suspendAll()

      Thread.sleep(3000)

      scheduler.shutdown()

      //Task 1 asserts
      task1ExecutionCount should be > 1
      task1ExecutionCountSnapshoot shouldEqual task1ExecutionCount

      //Task 2 asserts
      task2ExecutionCount should be > 1
      task2ExecutionCountSnapshoot shouldEqual task2ExecutionCount
    }

    "resume all suspended task" in {
      var task1ExecutionCount = 0
      var task2ExecutionCount = 0
      val task1 = getNewTask
      val task2 = getNewTask
      val scheduler = getScheduler { x =>
        if(x.schedule.id == task1.schedule.id) {
          task1ExecutionCount = task1ExecutionCount + 1
        }
        if(x.schedule.id == task2.schedule.id) {
          task2ExecutionCount = task2ExecutionCount + 1
        }
      }

      scheduler.schedule(task1)
      scheduler.schedule(task2)

      Thread.sleep(2000)

      val task1ExecutionCountSnapshoot = task1ExecutionCount
      val task2ExecutionCountSnapshoot = task2ExecutionCount

      scheduler.suspendAll()

      Thread.sleep(3000)

      //Task 1 asserts
      task1ExecutionCountSnapshoot shouldEqual task1ExecutionCount

      //Task 2 asserts
      task2ExecutionCountSnapshoot shouldEqual task2ExecutionCount

      scheduler.resumeAll()

      Thread.sleep(2000)

      scheduler.shutdown()


      //Task 1 asserts
      task1ExecutionCount should be > 1
      task1ExecutionCount should be > task1ExecutionCountSnapshoot


      //Task 2 asserts
      task2ExecutionCount should be > 1
      task2ExecutionCount should be > task2ExecutionCountSnapshoot
    }

    "resume a suspended task" in {
      var taskExecutionCount = 0
      val scheduler = getScheduler(x => taskExecutionCount = taskExecutionCount + 1)
      val task = getNewTask

      scheduler.schedule(task)

      Thread.sleep(2000)

      val taskExecutionCountSnapshoot = taskExecutionCount
      scheduler.suspend(task)

      Thread.sleep(2000)

      taskExecutionCountSnapshoot shouldEqual taskExecutionCount

      scheduler.resume(task)

      Thread.sleep(2000)

      scheduler.shutdown()

      taskExecutionCount should be > 1
      taskExecutionCount should be > taskExecutionCountSnapshoot
    }

    "throw an exception when two task with same id are scheduled" in {
      val scheduler = getScheduler(x => {})
      val task = getNewTask

      scheduler.schedule(task)

      an[DuplicatedTaskIdException] should be thrownBy {
        scheduler.schedule(task)
      }

      scheduler.shutdown()
    }
  }
}
*/