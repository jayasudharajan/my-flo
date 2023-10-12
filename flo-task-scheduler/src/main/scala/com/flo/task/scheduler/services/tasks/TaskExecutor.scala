package com.flo.task.scheduler.services.tasks

import akka.actor.{Actor, ActorLogging, Props}
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.Task
import com.flo.task.scheduler.domain.actors.Executed
import com.flo.task.scheduler.domain.actors.commands.Schedule
import com.flo.task.scheduler.services.IKafkaProducerRepository
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler
import scala.util.{Failure, Success}

class TaskExecutor(
                    taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                    kafkaProducerRepository: IKafkaProducerRepository,
                    taskSchedulerEndpoints: ITaskSchedulerEndpoints
                  )
  extends Actor with ActorLogging {

  import context.dispatcher

  var taskScheduler =
    taskSchedulerInstanceHandler
      .createInstance(self)
      .get()

  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created.
  def receive: Receive = {
    case Schedule(command) => {
      taskScheduler map { x =>
        log.info("Scheduling task: " + command.schedule.id)

        x.schedule(command)

        taskSchedulerEndpoints.logScheduled(command) onFailure {
          case ex: Exception =>
            log.error(ex, s"Task ${command.schedule.id} was not logged as scheduled due to an error on api")
        }

        log.info("Task scheduled: " + command.schedule.id)
      }
    }
    case command: Task => {

      taskScheduler map { x =>
        log.info("Executing task: " + command.schedule.id)

        //Send message to kafka
        val producer = kafkaProducerRepository.getByTopic(command.destinationTopic)
        producer.send[String](command.taskData, x => x)

        taskSchedulerEndpoints.logExecuted(command) onComplete {
          case Success(result) =>
            if (command.isOneTimer) {
              x.cancel(command)
            }
          case Failure(ex) =>
            log.error(ex, s"Task ${command.schedule.id} was not logged as executed due to an error on api")
        }

        //indicate to supervisor that the operation was a success
        context.parent ! Executed(command)

        log.info("Task executed: " + command.schedule.id)
      }
    }
  }
}

object TaskExecutor {
  def props(
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             kafkaProducerRepository: IKafkaProducerRepository,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints
           ): Props =
    Props(
      classOf[TaskExecutor],
      taskSchedulerInstanceHandler,
      kafkaProducerRepository,
      taskSchedulerEndpoints
    )
}