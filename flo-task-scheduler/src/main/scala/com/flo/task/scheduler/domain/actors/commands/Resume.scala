package com.flo.task.scheduler.domain.actors.commands

import com.flo.Models.KafkaMessages.SchedulerCommand

case class Resume(command: SchedulerCommand) extends Command
