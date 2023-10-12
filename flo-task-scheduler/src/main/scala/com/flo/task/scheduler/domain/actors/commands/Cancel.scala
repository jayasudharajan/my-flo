package com.flo.task.scheduler.domain.actors.commands

import com.flo.Models.KafkaMessages.SchedulerCommand

case class Cancel(command: SchedulerCommand) extends Command
