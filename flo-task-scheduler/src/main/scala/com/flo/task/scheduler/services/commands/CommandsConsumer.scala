package com.flo.task.scheduler.services.commands

import akka.actor.Props
import com.flo.FloApi.v2.ITaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.SchedulerCommand
import com.flo.communication.IKafkaConsumer
import com.flo.task.scheduler.services.KafkaActorConsumer
import com.flo.task.scheduler.utils.ITaskSchedulerInstanceHandler

class CommandsConsumer(
                        kafkaConsumer: IKafkaConsumer,
                        deserializer: String => SchedulerCommand,
                        taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
                        taskSchedulerEndpoints: ITaskSchedulerEndpoints,
                        filterTimeInSeconds: Int
                      )
  extends KafkaActorConsumer[SchedulerCommand](kafkaConsumer, deserializer, filterTimeInSeconds) {

  log.info("CommandsConsumer started!")

  val commandExecutorSupervisor = context.actorOf(
    CommandExecutorSupervisor.props(taskSchedulerInstanceHandler, taskSchedulerEndpoints),
    "command-executor-supervisor"
  )

  def consume(kafkaMessage: SchedulerCommand): Unit = {
    commandExecutorSupervisor ! kafkaMessage
  }
}

object CommandsConsumer {
  def props(
             kafkaConsumer: IKafkaConsumer,
             deserializer: String => SchedulerCommand,
             taskSchedulerInstanceHandler: ITaskSchedulerInstanceHandler,
             taskSchedulerEndpoints: ITaskSchedulerEndpoints,
             filterTimeInSeconds: Int
           ): Props = Props(
    classOf[CommandsConsumer],
    kafkaConsumer,
    deserializer,
    taskSchedulerInstanceHandler,
    taskSchedulerEndpoints,
    filterTimeInSeconds
  )
}

