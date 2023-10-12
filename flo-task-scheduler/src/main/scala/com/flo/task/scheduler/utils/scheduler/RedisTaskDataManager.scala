package com.flo.task.scheduler.utils.scheduler

import com.flo.Models.KafkaMessages.Task
import com.flo.utils.{FromCamelToSneakCaseSerializer, FromSneakToCamelCaseDeserializer}
import com.redis.{RedisClient, RedisClientPool}

class RedisTaskDataManager(redisHost: String, redisPort: Int) extends TaskDataManager {

  val redisClientsPool = new RedisClientPool(redisHost, redisPort)
  val serializer = new FromCamelToSneakCaseSerializer
  val deserializer = new FromSneakToCamelCaseDeserializer
  val pageSize = 100
  val redisTasksKey = "redisson-task-scheduler:tasks"

  private def serialize(taskInfo: TaskInfo): String = {
    serializer.serialize[TaskInfo](taskInfo)
  }

  private def deserialize(taskInfoJson: String): TaskInfo = {
    deserializer.deserialize[TaskInfo](taskInfoJson)
  }

  private def withTaskInfo(redisClient: RedisClient, taskId: String, taskInfoConsumer: TaskInfo => Unit): Unit =
    redisClient.hget(
      redisTasksKey,
      taskId
    ) map { taskInfo =>
      taskInfoConsumer(
        deserialize(taskInfo)
      )
    }

  private def getPaginatedFromCursor(cursor: Int = 0): List[TaskInfo] = {
    def isJson(value: String) =
      value.trim.startsWith("{")

    redisClientsPool.withClient {
      redis => {
        redis.hscan(redisTasksKey, cursor, "*", pageSize) match {
          case Some((Some(newCursor), Some(tasks))) => {
            val result = tasks.filter(x => isJson(x.getOrElse(""))).map { taskInfoJson =>
              deserializer.deserialize[TaskInfo](taskInfoJson.get)
            }

            if(newCursor > 0) {
              result ++ getPaginatedFromCursor(newCursor)
            } else {
              result
            }
          }
          case x => Nil
        }
      }
    }
  }

  def withTaskInfo(taskId: String, taskInfoConsumer: TaskInfo => Unit): Unit = {
    redisClientsPool.withClient { redis =>
      withTaskInfo(redis, taskId, taskInfoConsumer)
    }
  }

  def get(taskId: String): Option[TaskInfo] = {
    redisClientsPool.withClient { redis =>
      redis.hget(
        redisTasksKey,
        taskId
      ) map { taskInfo =>
        deserialize(taskInfo)
      }
    }
  }

  def getAll(): List[TaskInfo] = {
    getPaginatedFromCursor(0)
  }

  def updateAll(updater: TaskInfo => TaskInfo): Unit = {
    getPaginatedFromCursor(0) foreach { taskInfoJson =>
      save(
        updater(taskInfoJson)
      )
    }
  }

  def update(taskId: String, updater: TaskInfo => TaskInfo): Unit = {
    redisClientsPool.withClient { redis =>
      withTaskInfo(
        redis,
        taskId,
        taskInfo =>
          redis.hset(
            redisTasksKey,
            taskId,
            serialize(
              updater(taskInfo)
            )
          )
      )
    }
  }

  def save(taskInfo: TaskInfo): Unit = {
    redisClientsPool.withClient { redis =>
      redis.hset(
        redisTasksKey,
        taskInfo.task.schedule.id,
        serializer.serialize[TaskInfo](taskInfo)
      )
    }
  }

  def remove(taskId: String): Unit = {
    redisClientsPool.withClient { redis =>
      redis.hdel(redisTasksKey, taskId)
    }
  }

  def exists(task: Task): Boolean = {
    exists(task.schedule.id)
  }

  def exists(taskId: String): Boolean = {
    redisClientsPool.withClient { redis =>
      redis.hexists("redisson-task-scheduler:tasks", taskId)
    }
  }
}
