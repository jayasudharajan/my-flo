package com.flo.task.scheduler.domain.actors.commands

import com.flo.Models.KafkaMessages.SchedulerCommand

case class Suspend(command: SchedulerCommand) extends Command
