package com.flo.task.scheduler.domain.actors.commands

import com.flo.Models.KafkaMessages.Task

case class Schedule(task: Task) extends Command
