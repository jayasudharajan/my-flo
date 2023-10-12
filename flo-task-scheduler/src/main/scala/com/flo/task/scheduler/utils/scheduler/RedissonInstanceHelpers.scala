package com.flo.task.scheduler.utils.scheduler

import org.redisson.Redisson
import org.redisson.api.RScheduledExecutorService
import org.redisson.config.Config

trait RedissonInstanceHelpers {
  val redisHost: String
  val redisPort: Int

  private var executorServices: Map[String, RScheduledExecutorService] = Map()
  private val client = Redisson.create(getRedissonConfig())

  def getRedissonConfig(): Config = {
    val config = new Config()

    config
      .useSingleServer()
      .setAddress(s"redis://$redisHost:$redisPort")

    config
  }

  def getExecutorServiceByName(name: String): RScheduledExecutorService = {
    executorServices.get(name) match {
      case Some(executor) => executor
      case None => {
        val executor = client.getExecutorService(name)

        executorServices = executorServices + (name -> executor)
        executor
      }
    }
  }
}
