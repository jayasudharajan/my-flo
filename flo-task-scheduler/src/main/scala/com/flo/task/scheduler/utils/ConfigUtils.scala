package com.flo.task.scheduler.utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory

object ConfigUtils {

  val config = ConfigFactory.load()

  val kafka = new {
    private val kafkaConfig = config.getConfig("kafka")
    private val topicsConfig = kafkaConfig.getConfig("topics")

    val host = kafkaConfig.getString("host")
    val groupId = kafkaConfig.getString("group-id")
    val encryption = kafkaConfig.getBoolean("encryption")
    val topics = new {
      val tasks = topicsConfig.getString("tasks")
      val schedulerCommands = topicsConfig.getString("scheduler-commands")
    }
    val filterTimeInSeconds = kafkaConfig.getInt("filter-time-in-seconds")
    val maxPollRecords = kafkaConfig.getLong("max-poll-records")
    val pollTimeout = kafkaConfig.getLong("poll-timeout")
  }

  val pingPort = config.getInt("ping-port")

  val cipher = new {
    private val cipherConfig = config.getConfig("cipher")

    val keyProvider =  new {
      private val keyProviderConfig = cipherConfig.getConfig("key-provider")

      val bucketRegion = Region.getRegion(Regions.fromName(keyProviderConfig.getString("bucket-region")))
      val bucketName = keyProviderConfig.getString("bucket-name")
      val keyPathTemplate = keyProviderConfig.getString("key-path-template")
      val keyId = keyProviderConfig.getString("key-id")
    }
  }

  val redis = new {
    private val redisConfig = config.getConfig("redis")

    val host = redisConfig.getString("host")
    val port = redisConfig.getInt("port")
  }

  val scheduler = new {
    private val schedulerConfig = config.getConfig("scheduler")

    val id = schedulerConfig.getString("id")
    val numberOfExecutorServices = schedulerConfig.getInt("number-of-executor-services")
  }
}
