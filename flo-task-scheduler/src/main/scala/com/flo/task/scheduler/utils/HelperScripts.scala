package com.flo.task.scheduler.utils

import com.flo.Models.KafkaMessages.{Schedule, SchedulerCommand, Task}
import com.flo.task.scheduler.services.KafkaProducerRepository
import com.flo.task.scheduler.utils.scheduler.RedisTaskDataManager
import com.flo.utils.FromCamelToSneakCaseSerializer
import org.joda.time.{DateTime, DateTimeZone}

import scala.util.Random

class HelperScripts(
                     redisHost: String,
                     redisPort: Int,
                     kafkaProducerRepository: KafkaProducerRepository,
                     encrypt: String => String
                   ) extends UUIDGenerator with Logging {

  val serializer = new FromCamelToSneakCaseSerializer

  def getTestTask(id: String): Task = new Task(
    "test",
    s"$id: I am Alive!!!",
    Schedule(
      id,
      None,
      "*/10 * * ? * *",
      "America/Argentina/Buenos_Aires",
      None,
      None
    ),
    None
  )

  def scheduleOneTimerAt(seconds: Int, destinationTopic: String, taskData: String): String = {
    val taskId = uuid()
    val date = new DateTime(DateTimeZone.UTC).plus(seconds * 1000L)

    val task = Task(
      destinationTopic,
      taskData,
      Schedule(
        taskId,
        None,
        s"${date.getSecondOfMinute} ${date.getMinuteOfHour} ${date.getHourOfDay} ${date.getDayOfMonth()} ${date.getMonthOfYear()} ? ${date.getYear()}",
        "America/Argentina/Buenos_Aires",
        None,
        None
      ),
      None
    )

    scheduleTask(task)

    taskId
  }

  def scheduleTask(task: Task): Unit = {
    val taskCommandsProducer = kafkaProducerRepository.getByTopic(ConfigUtils.kafka.topics.tasks)

    logger.info(s"Scheduling task with id ${task.schedule.id} and expression ${task.schedule.id}")

    taskCommandsProducer.send[Task](task, x => encrypt(serializer.serialize[Task](x)))

    logger.info("scheduleTask finished successfully!!!")
  }

  def cancelTask(taskId: String): Unit = {
    val taskCommandsProducer = kafkaProducerRepository.getByTopic(ConfigUtils.kafka.topics.schedulerCommands)
    val cancelCommand = SchedulerCommand("cancel", taskId = Some(taskId))

    taskCommandsProducer.send[SchedulerCommand](cancelCommand, x => encrypt(serializer.serialize[SchedulerCommand](x)))

    logger.info("cancelTask finished successfully!!!")
  }

  def runTestTask(): Task = {
    val taskSchedulerProducer = kafkaProducerRepository.getByTopic(ConfigUtils.kafka.topics.tasks)

    logger.info("Running test task")

    val task = getTestTask(s"test-task:${uuid()}")

    taskSchedulerProducer.send[Task](task.copy(shouldOverride = Some(true)), x => encrypt(serializer.serialize[Task](x)))

    logger.info("runTestTask finished successfully!!!")

    task
  }

  def rescheduleAllTasks(): Unit = {
    val redisTaskManager = new RedisTaskDataManager(redisHost, redisPort)
    val taskSchedulerProducer = kafkaProducerRepository.getByTopic(ConfigUtils.kafka.topics.tasks)
    val tasksToReschedule = redisTaskManager.getAll().reverse

    logger.info(s"${tasksToReschedule.size} tasks will be rescheduled")

    tasksToReschedule.foreach(taskInfo => {
      logger.info(s"Rescheduling task ${taskInfo.task.schedule.id}")

      taskSchedulerProducer.send[Task](taskInfo.task.copy(shouldOverride = Some(true)), x => encrypt(serializer.serialize[Task](x)))

      logger.info(s"Task ${taskInfo.task.schedule.id} rescheduled")
    })

    logger.info("rescheduleAllTasks finished successfully!!!")
  }

  private def selectRandom(nodes: List[String]): String = {
    val random = new Random()
    nodes(random.nextInt(nodes.size))
  }
}
