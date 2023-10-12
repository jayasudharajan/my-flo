package com.flo.task.scheduler.utils.scheduler

import com.flo.Models.KafkaMessages.Task

case class TaskInfo(task: Task, redissonInfo: RedissonInfo, state: String = "running") {

  val running = "running"
  val suspended = "suspended"

  def suspend(): TaskInfo =
    copy(state = suspended)

  def resume(): TaskInfo =
    copy(state = running)

  def isRunning: Boolean =
    state == running

  def isSuspended: Boolean =
    !isRunning
}
