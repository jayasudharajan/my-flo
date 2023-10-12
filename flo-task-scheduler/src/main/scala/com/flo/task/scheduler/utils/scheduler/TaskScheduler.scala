package com.flo.task.scheduler.utils.scheduler

import java.util.concurrent.TimeUnit
import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import akka.stream.scaladsl.{Sink, Source}
import com.flo.Models.KafkaMessages.Task
import com.flo.task.scheduler.utils.Logging
import org.joda.time.DateTime
import org.redisson.api.CronSchedule

class TaskScheduler(
                     id: String,
                     redisHost: String,
                     redisPort: Int,
                     taskExecutor: Task => Unit,
                     numberOfExecutorServices: Int = 1
                   ) extends ITaskScheduler with Logging {

  require(numberOfExecutorServices > 0, "numberOfExecutorServices should be at least 1.")
  require(!id.isEmpty, "id should not be an empty.")

  val nodeRegistryManager = new RedissonNodesManager(id, redisHost, redisPort, numberOfExecutorServices)
  val redisTaskManager = new RedisTaskDataManager(redisHost, redisPort)

  logger.info(s"Task scheduler $id started.")

  nodeRegistryManager.nodeIds.map(nodeId => TaskScheduler.register(nodeId, taskExecutor))
  nodeRegistryManager.runOwnedNodes()

  private def toDelayInMillis(oneTimerCronExpression: String): Long = {
    val pattern = "^(\\d{1,2}) (\\d{1,2}) (\\d{1,2}) (\\d{1,2}) ([a-zA-Z]{3}|\\d{1,2}) \\? (\\d{4})$".r
    val pattern(seconds, minutes, hours, day, month, year) = oneTimerCronExpression
    val executionDate = new DateTime(year.toInt, month.toInt, day.toInt, hours.toInt, minutes.toInt, seconds.toInt)
    executionDate.getMillis - new DateTime().getMillis
  }

  def schedule(task: Task): Unit = {
    val nodeId = nodeRegistryManager.getOwnedNodeId()
    val executorService = nodeRegistryManager.getExecutorServiceByNode(nodeId)
    val shouldOverride = task.shouldOverride.getOrElse(false)
    val alreadyScheduled = isScheduled(task)
    val isAReschedule = shouldOverride && alreadyScheduled

    if(isAReschedule) {
      cancel(task)
    } else if(alreadyScheduled) {
      throw new DuplicatedTaskIdException()
    }

    val taskRunner = new TaskScheduler.TaskRunner(
      nodeId,
      redisHost,
      redisPort,
      redisTaskManager.redisTasksKey,
      task.schedule.id
    )

    val scheduleResult = if(task.isOneTimer) {
      val delay = toDelayInMillis(task.schedule.expression)

      executorService.scheduleAsync(
        taskRunner,
        delay,
        TimeUnit.MILLISECONDS
      )
    } else {
      executorService.scheduleAsync(
        taskRunner,
        CronSchedule.of(task.schedule.expression)
      )
    }

    val redissonTaskId = scheduleResult.getTaskId
    val taskWithState = TaskInfo(
      task,
      RedissonInfo(redissonTaskId, executorService.getName)
    )

    redisTaskManager.save(taskWithState)

    if(alreadyScheduled) {
      logger.info(s"Task ${task.schedule.id} was rescheduled.")
    } else {
      logger.info(s"Task ${task.schedule.id} was scheduled.")
    }
  }

  def cancel(taskId: String): Unit = {
    redisTaskManager.withTaskInfo(
      taskId,
      taskInfo => {
        val executorService = nodeRegistryManager.getExecutorServiceByName(taskInfo.redissonInfo.executorServiceName)

        executorService.cancelTask(taskInfo.redissonInfo.redissonTaskId)
        redisTaskManager.remove(taskId)
        logger.info(s"Task ${taskId} was canceled. Redisson task id: ${taskInfo.redissonInfo.redissonTaskId}")
      }
    )
  }

  def suspend(taskId: String): Unit = {
    redisTaskManager.update(taskId, taskInfo => taskInfo.suspend())
    logger.info(s"Task ${taskId} was suspended.")
  }

  def suspendAll(): Unit = {
    redisTaskManager.updateAll { taskInfo =>
      taskInfo.suspend()
    }
    logger.info(s"All tasks were suspended.")
  }

  def resume(taskId: String): Unit = {
    redisTaskManager.update(taskId, taskInfo => taskInfo.resume())
    logger.info(s"Task ${taskId} was resumed.")
  }

  def resumeAll(): Unit = {
    redisTaskManager.updateAll { taskInfo =>
      taskInfo.resume()
    }
    logger.info(s"All tasks were suspended.")
  }

  def isScheduled(task: Task): Boolean =
    redisTaskManager.exists(task)
}


object TaskScheduler extends Logging {
  val nodesRegistryRedisKey = "task-scheduler:nodes-registry"

  private var consumerManagers: Map[String, ConsumerManager] = Map()

  def register(nodeId: String, executor: Task => Unit): Unit = {
    if(isRegistered(nodeId)) {
      throw new Exception("Only one consumer per task scheduler is allowed.")
    }
    consumerManagers = consumerManagers ++ Map(nodeId -> new ConsumerManager(executor))
  }

  def isRegistered(nodeId: String): Boolean = {
    consumerManagers.get(nodeId).isDefined
  }

  private def push(taskSchedulerId: String, task: Task): Unit = {
    consumerManagers.get(taskSchedulerId).map(x => x.push(task))
  }

  protected class ConsumerManager(executor: Task => Unit) {

    implicit val system = ActorSystem()
    implicit val materializer = ActorMaterializer()

    private val overflowStrategy = akka.stream.OverflowStrategy.dropHead
    private val source = Source.actorRef[Task](Int.MaxValue, overflowStrategy)

    private val runneable = source.to(Sink foreach executor)
    private val ref = runneable.run()

    def push(task: Task): Unit = {
      ref ! task
    }
  }

  protected class TaskRunner(
                              taskSchedulerId: String,
                              redisHost: String,
                              redisPort: Int,
                              redisTasksKey: String,
                              taskId: String
                            ) extends Runnable {


    def this() {
      this("", "", 1, "", "")
    }

    @Override
    override def run(): Unit = {
      //if (!Thread.currentThread().isInterrupted() && shouldBeExecutedInThisMachine(taskSchedulerId)) {
      if (!Thread.currentThread().isInterrupted()) {

        // Task was not canceled
        val redisTaskManager = new RedisTaskDataManager(redisHost, redisPort)

        redisTaskManager.get(
          taskId
        ) match {
          case Some(taskInfo) => {


            if(taskInfo.isRunning) {
              // Task is not suspended
              logger.info(s"Queueing task ${taskInfo.task.schedule.id} to be executed.")
              push(taskSchedulerId, taskInfo.task)
            }
          }
          case None =>
        }
      }
    }
  }
}