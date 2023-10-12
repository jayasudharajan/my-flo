package com.flo.task.scheduler.services

import akka.actor.{ActorRef, ActorSystem}
import akka.testkit.{ImplicitSender, TestKit}
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.{Schedule, SchedulerCommand, Task}
import com.flo.communication.IKafkaProducer
import com.flo.task.scheduler.domain.actors.commands.{Command, _}
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler
import com.flo.task.scheduler.utils.scheduler.ITaskScheduler
import org.apache.kafka.clients.producer.RecordMetadata
import org.apache.kafka.common.TopicPartition
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}

import scala.concurrent.Future

abstract class BaseActorsSpec extends TestKit(ActorSystem("MySpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll {

  import system.dispatcher

  override def afterAll(): Unit = {
    TestKit.shutdownActorSystem(system)
  }

  def getTask(data: String = "data"): Task = {
    Task(
      "onetopic",
      data,
      Schedule(
        java.util.UUID.randomUUID.toString,
        Some("weeklyReport"),
        "*/1 * * ? * *",
        "UTC",
        None,
        None
      ),
      None
    )
  }

  val task1 = getTask("data1")
  val task2 = getTask("data2")

  val command1 = SchedulerCommand(
    "cancel",
    Some("1")
  )

  val command2 = SchedulerCommand(
    "resume",
    Some("2")
  )

  val executorCommand1 = Cancel(command1)
  val executorCommand2 = Resume(command2)

  val taskEndpoints = new ITaskSchedulerEndpoints {

    override def logExecuted(task: Task): Future[Boolean] = Future(true)

    override def logScheduled(task: Task): Future[Boolean] = Future(true)

    override def logCanceled(command: SchedulerCommand): Future[Boolean] = Future(true)

    override def logSuspend(command: SchedulerCommand): Future[Boolean] = Future(true)

    override def logResume(command: SchedulerCommand): Future[Boolean] = Future(true)

    override def logSent(task: Task, deviceId: Option[String], taskType: Option[String]): Future[Boolean] = Future(true)

    override def logCancelSent(command: SchedulerCommand): Future[Boolean] = Future(true)
  }

  def getInstanceHandler(failAtFirstTime: Boolean) =
    new ITaskSchedulerInstanceHandler {
      private var taskScheduler = getScheduler(failAtFirstTime, ActorRef.noSender)

      override def createInstance(taskExecutor: ActorRef): ITaskSchedulerInstanceHandler = {
        taskScheduler = getScheduler(failAtFirstTime, taskExecutor)
        this
      }

      override def get(): Option[ITaskScheduler] =
        Some(taskScheduler)

      def getReal() = taskScheduler
    }

  def getScheduler(failAtFirstTime: Boolean, taskExecutor: ActorRef) =
    new ITaskScheduler {
      private var tasks: List[Task] = Nil
      private var commands: List[Command] = Nil

      private var attempts = 0

      def getAttempts = attempts

      def getTasks = tasks.reverse

      def getCommands = commands.reverse

      private def failAtFirstAttemp(): Unit = {
        attempts = attempts + 1

        if (failAtFirstTime && attempts <= 1) {
          throw new Exception("ShouldFail error.")
        }
      }

      override def schedule(command: Task): Unit = {
        failAtFirstAttemp()
        tasks = command :: tasks
        taskExecutor ! command
      }

      override def isScheduled(taskCommand: Task): Boolean = {
        tasks.contains(taskCommand)
      }

      override def cancel(taskId: String): Unit = {
        failAtFirstAttemp()
        commands = Cancel(SchedulerCommand("cancel", Some(taskId))) :: commands
        tasks = tasks.filterNot(x => x.schedule.id == taskId)
      }

      override def cancel(task: Task): Unit = {
        failAtFirstAttemp()
        commands = Cancel(SchedulerCommand("cancel", Some(task.schedule.id))) :: commands
        tasks = tasks.filterNot(x => x == task)
      }

      override def suspend(taskId: String): Unit = {
        failAtFirstAttemp()
        commands = Suspend(SchedulerCommand("suspend", Some(taskId))) :: commands
      }

      override def suspendAll(): Unit = {
        failAtFirstAttemp()
        commands = SuspendAll() :: commands
      }

      override def resume(taskId: String): Unit = {
        failAtFirstAttemp()
        commands = Resume(SchedulerCommand("resume", Some(taskId))) :: commands
      }

      override def resumeAll(): Unit = {
        failAtFirstAttemp()
        commands = ResumeAll() :: commands
      }
    }

  def getKafkaProducerRepository() = new IKafkaProducerRepository {
    val producer = new IKafkaProducer {
      private var messages: List[Any] = Nil

      def getMessages: List[Any] = messages.reverse

      override def send[T <: AnyRef](message: T, serializer: (T) => String): RecordMetadata = {
        messages = message::messages
        new RecordMetadata(new TopicPartition("test", 1), 10L, 100L, 433423L, 12322L, 1024, 1024)
      }
    }
    override def getByTopic(topic: String): IKafkaProducer =
        producer
  }
}
