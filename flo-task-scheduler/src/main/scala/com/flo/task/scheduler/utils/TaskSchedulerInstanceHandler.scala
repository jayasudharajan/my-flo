package com.flo.task.scheduler.utils

import akka.actor.ActorRef
import com.flo.task.scheduler.utils.scheduler.{ITaskScheduler, TaskScheduler}

class TaskSchedulerInstanceHandler(
                                    taskSchedulerId: String,
                                    redisHost: String,
                                    redisPort: Int,
                                    numberOfExecutorServices: Int
                                  ) extends ITaskSchedulerInstanceHandler {

  private var taskScheduler: Option[ITaskScheduler] = None

  def createInstance(taskExecutor: ActorRef): ITaskSchedulerInstanceHandler = {
    if(taskScheduler.isEmpty) {
      taskScheduler = Some(
        new TaskScheduler(
          taskSchedulerId,
          redisHost,
          redisPort,
          task => taskExecutor ! task,
          numberOfExecutorServices
        )
      )
    }
    this
  }

  def get(): Option[ITaskScheduler] =
    taskScheduler
}

trait ITaskSchedulerInstanceHandler {
  def createInstance(taskExecutor: ActorRef): ITaskSchedulerInstanceHandler

  def get(): Option[ITaskScheduler]
}