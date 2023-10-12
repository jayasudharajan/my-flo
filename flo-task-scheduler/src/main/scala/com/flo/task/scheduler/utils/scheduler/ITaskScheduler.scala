package com.flo.task.scheduler.utils.scheduler

import com.flo.Models.KafkaMessages.Task

trait ITaskScheduler {
  def schedule(task: Task): Unit

  def cancel(taskId: String): Unit

  def cancel(task: Task): Unit = {
    cancel(task.schedule.id)
  }

  def suspend(taskId: String): Unit

  def suspend(task: Task): Unit =  {
    suspend(task.schedule.id)
  }

  def suspendAll(): Unit

  def resume(taskId: String): Unit

  def resume(task: Task): Unit =  {
    resume(task.schedule.id)
  }

  def resumeAll(): Unit

  def isScheduled(task: Task): Boolean
}
