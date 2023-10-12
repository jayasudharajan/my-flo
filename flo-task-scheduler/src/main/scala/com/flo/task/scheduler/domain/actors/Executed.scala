package com.flo.task.scheduler.domain.actors

import com.flo.Models.KafkaMessages.Task

case class Executed(task: Task)
