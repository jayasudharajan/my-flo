package com.flo.task.scheduler.services.tasks

import akka.actor.SupervisorStrategy.Restart
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.task.scheduler.domain.actors.Executed
import com.flo.task.scheduler.domain.actors.commands.Schedule
import com.flo.task.scheduler.services.IKafkaProducerRepository
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler

class TaskExecutorSupervisor(
                              taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                              kafkaProducerRepository: IKafkaProducerRepository,
                              taskSchedulerEndpoints: ITaskSchedulerEndpoints
                            ) extends Actor with ActorLogging {

  log.info("TaskExecutorSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: Exception =>
      log.error(e, "There was an error when trying to run task command, restarting.")
      Restart
  }

  val taskExecutor = context.actorOf(
    TaskExecutor.props(
      taskSchedulerInstanceHandler,
      kafkaProducerRepository,
      taskSchedulerEndpoints
    ),
    "task-executor"
  )

  def receive: Receive = {
    case command @ Schedule(task) => {
      taskExecutor ! command
    }
    case Executed(command) =>
  }
}

object TaskExecutorSupervisor {
  def props(
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             kafkaProducerRepository: IKafkaProducerRepository,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints
           ): Props = Props(
    classOf[TaskExecutorSupervisor],
    taskSchedulerInstanceHandler,
    kafkaProducerRepository,
    taskSchedulerEndpoints
  )
}




