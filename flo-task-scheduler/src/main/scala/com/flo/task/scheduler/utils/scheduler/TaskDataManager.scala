package com.flo.task.scheduler.utils.scheduler

import com.flo.Models.KafkaMessages.Task

trait TaskDataManager {
  def withTaskInfo(taskId: String, taskInfoConsumer: TaskInfo => Unit): Unit
  def get(taskId: String): Option[TaskInfo]
  def getAll(): List[TaskInfo]
  def updateAll(updater: TaskInfo => TaskInfo): Unit
  def update(taskId: String, updater: TaskInfo => TaskInfo): Unit
  def save(taskInfo: TaskInfo): Unit
  def remove(taskId: String): Unit
  def exists(task: Task): Boolean
  def exists(taskId: String): Boolean
}
