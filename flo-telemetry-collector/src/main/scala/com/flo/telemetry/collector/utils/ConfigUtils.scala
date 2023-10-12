package com.flo.telemetry.collector.utils

import com.typesafe.config.ConfigFactory

object ConfigUtils {

  val config = ConfigFactory.load()

  val kafka = new {
    private val path = "kafka"
    val host = config.getString(s"$path.host")
    val groupId = config.getString(s"$path.group-id")
    val sourceTopic = config.getString(s"$path.source-topic")
    val destinationTopic = config.getString(s"$path.destination-topic")
    val filterTimeInSeconds = config.getInt(s"$path.filter-time-in-seconds")
  }

  val pingPort = config.getInt("ping-port")
}
