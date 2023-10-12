package com.flo.router.telemetry.utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory
import org.influxdb.InfluxDB.LogLevel
import collection.JavaConverters._

object ConfigUtils {

  val config = ConfigFactory.load()

  private val logLevelMapper = Map(
    "FULL" -> LogLevel.FULL,
    "BASIC" -> LogLevel.BASIC,
    "HEADERS" -> LogLevel.HEADERS,
    "NONE" -> LogLevel.NONE
  )

  case class InfluxDBConfig(
                             host: String,
                             port: Int,
                             username: String,
                             password: String,
                             database: String,
                             retentionPolicy: String,
                             measurement: String
                           )
  
  val influx = new {
    val influxConfig = config.getConfig("influx")
    val logLevelName = influxConfig.getString("log-level")
    val influxDatabasesConfigs = influxConfig.getConfigList("databases")
    val influxBadDataDatabasesConfigs = influxConfig.getConfigList("bad-data-databases")

    val databases = influxDatabasesConfigs.asScala.map { databaseConfig =>
      InfluxDBConfig(
        databaseConfig.getString("host"),
        databaseConfig.getInt("port"),
        databaseConfig.getString("username"),
        databaseConfig.getString("password"),
        databaseConfig.getString("database"),
        databaseConfig.getString("retention-policy"),
        databaseConfig.getString("measurement")
      )
    }

    val badDataDatabases  = influxBadDataDatabasesConfigs.asScala.map { databaseConfig =>
      InfluxDBConfig(
        databaseConfig.getString("host"),
        databaseConfig.getInt("port"),
        databaseConfig.getString("username"),
        databaseConfig.getString("password"),
        databaseConfig.getString("database"),
        databaseConfig.getString("retention-policy"),
        databaseConfig.getString("measurement")
      )
    }

    val logLevel = logLevelMapper.getOrElse(logLevelName, LogLevel.BASIC)
  }

  val kafka = new {
    private val path = "kafka"
    val host = config.getString(s"$path.host")
    val groupId = config.getString(s"$path.group-id")
    val topic = config.getString(s"$path.topic")
    val avroTopic = config.getString(s"$path.avro-topic")
    val filterTimeInSeconds = config.getInt(s"$path.filter-time-in-seconds")
    val maxPollRecords = config.getLong(s"$path.max-poll-records")
    val pollTimeout = config.getLong(s"$path.poll-timeout")
    val schemaRegistry = config.getString(s"$path.schema-registry")
  }

  val pingPort = config.getInt("ping-port")

  val telemetry = new {
    private val telemetryConfig = config.getConfig("telemetry")

    val filters =  new {
      private val filtersConfig = telemetryConfig.getConfig("filters")

      val timestampThresholdInDays = filtersConfig.getInt("timestamp-threshold-in-days")
    }
  }
}
