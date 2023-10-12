package com.flo.task.scheduler.services.commands

import akka.actor.{Actor, ActorLogging, Props}
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.task.scheduler.domain.actors.commands._
import com.flo.task.scheduler.services.commands.CommandExecutorSupervisor.Executed
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler
import com.flo.task.scheduler.utils.scheduler.ITaskScheduler

class CommandExecutor(
                       taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                       taskSchedulerEndpoints: ITaskSchedulerEndpoints
                     )
  extends Actor with ActorLogging {

  import context.dispatcher

  def taskScheduler(): Option[ITaskScheduler] = taskSchedulerInstanceHandler.get()

  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created.
  def receive: Receive = {
    case Cancel(command) => {
      command.taskId map { taskId =>

        taskScheduler map { x =>
          log.info("Cancel task:" + taskId)

          x.cancel(taskId)

          taskSchedulerEndpoints.logCanceled(command) onFailure {
            case x: Exception => log.error(x, "Api failed to log the task status")
          }

          log.info("Task canceled: " + taskId)
          context.parent ! Executed
        }
      }
    }
    case Suspend(command) => {
      command.taskId map { taskId =>

        taskScheduler map { x =>
          log.info("Suspend task:" + taskId)

          x.suspend(taskId)

          taskSchedulerEndpoints.logSuspend(command) onFailure {
            case x: Exception => log.error(x, "Api failed to log the task status")
          }

          log.info("Task suspended: " + taskId)
          context.parent ! Executed
        }
      }
    }
    case SuspendAll() => {

      taskScheduler map { x =>
        log.info("Suspend all tasks")

        x.suspendAll()

        log.info("All tasks were suspended")
        context.parent ! Executed
      }
    }
    case Resume(command) => {
      command.taskId map { taskId =>

        taskScheduler map { x =>
          log.info("Resume task:" + taskId)

          x.resume(taskId)

          taskSchedulerEndpoints.logResume(command) onFailure {
            case x: Exception => log.error(x, "Api failed to log the task status")
          }

          log.info("Task resumed: " + taskId)
          context.parent ! Executed
        }
      }
    }
    case ResumeAll() => {

      taskScheduler map { x =>
        log.info("Resume all tasks")

        x.resumeAll()

        log.info("All tasks were resumed")
        context.parent ! Executed
      }
    }
  }
}

object CommandExecutor {
  def props(
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints
           ): Props =
    Props(classOf[CommandExecutor], taskSchedulerInstanceHandler, taskSchedulerEndpoints)
}
