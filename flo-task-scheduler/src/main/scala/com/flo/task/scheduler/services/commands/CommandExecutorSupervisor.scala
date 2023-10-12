package com.flo.task.scheduler.services.commands

import akka.actor.SupervisorStrategy.Restart
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.SchedulerCommand
import com.flo.task.scheduler.domain.actors.commands.{Command, _}
import com.flo.task.scheduler.services.commands.CommandExecutorSupervisor.Executed
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler

class CommandExecutorSupervisor(
                                 taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                                 taskSchedulerEndpoints: ITaskSchedulerEndpoints
                               ) extends Actor with ActorLogging {

  log.info("CommandExecutorSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: Exception =>
      log.error(e, "There was an error when trying to run task command, restarting.")
      Restart
  }

  val commandExecutor = context.actorOf(
    CommandExecutor.props(
      taskSchedulerInstanceHandler,
      taskSchedulerEndpoints
    )
  )

  def toExecutorCommand(schedulerCommand: SchedulerCommand): Option[Command] = {
    schedulerCommand match {
      case command if command.action == Command.cancel => Some(Cancel(command))
      case command if command.action == Command.suspend => Some(Suspend(command))
      case command if command.action == Command.suspendAll => Some(SuspendAll())
      case command if command.action == Command.resume => Some(Resume(command))
      case command if command.action == Command.resumeAll => Some(ResumeAll())
      case _ => None
    }
  }

  def receive: Receive = {
    case command: SchedulerCommand => {
      toExecutorCommand(command) map { command =>
        commandExecutor ! command
      }
    }
    case Executed =>
  }
}

object CommandExecutorSupervisor {
  object Executed

  def props(
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints
           ): Props = Props(
    classOf[CommandExecutorSupervisor],
    taskSchedulerInstanceHandler,
    taskSchedulerEndpoints
  )
}




