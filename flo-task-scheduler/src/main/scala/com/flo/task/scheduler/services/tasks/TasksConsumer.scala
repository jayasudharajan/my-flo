package com.flo.task.scheduler.services.tasks

import akka.actor.Props
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.Task
import com.flo.communication.IKafkaConsumer
import com.flo.task.scheduler.domain.actors.commands.Schedule
import com.flo.task.scheduler.services.{IKafkaProducerRepository, KafkaActorConsumer}
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler

class TasksConsumer(
                      kafkaConsumer: IKafkaConsumer,
                      kafkaProducerRepository: IKafkaProducerRepository,
                      deserializer: String => Task,
                      taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                      taskSchedulerEndpoints: ITaskSchedulerEndpoints,
                      filterTimeInSeconds: Int
                   )
  extends KafkaActorConsumer[Task](kafkaConsumer, deserializer, filterTimeInSeconds) {

    log.info("TasksConsumer started!")

    val commandExecutorSupervisor = context.actorOf(
      TaskExecutorSupervisor.props(
        taskSchedulerInstanceHandler,
        kafkaProducerRepository,
        taskSchedulerEndpoints
      ),
      "task-executor-supervisor"
    )

    def consume(kafkaMessage: Task): Unit = {
      commandExecutorSupervisor ! Schedule(kafkaMessage)
    }
  }

object TasksConsumer {
  def props(
             kafkaConsumer: IKafkaConsumer,
             kafkaProducerRepository: IKafkaProducerRepository,
             deserializer: String => Task,
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints,
             filterTimeInSeconds: Int
           ): Props = Props(
    classOf[TasksConsumer],
    kafkaConsumer,
    kafkaProducerRepository,
    deserializer,
    taskSchedulerInstanceHandler,
    taskSchedulerEndpoints,
    filterTimeInSeconds
  )
}

