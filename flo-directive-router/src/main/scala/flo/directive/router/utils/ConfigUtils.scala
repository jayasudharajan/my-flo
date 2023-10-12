package flo.directive.router.utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory

object ConfigUtils {

  val config = ConfigFactory.load()

  val kafka = new {
    private val path = "kafka"
    val host = config.getString(s"$path.host")
    val groupId = config.getString(s"$path.group-id")
    val topic = config.getString(s"$path.topic")
    val maxPollRecords = config.getLong(s"$path.max-poll-records")
    val pollTimeout = config.getLong(s"$path.poll-timeout")
    val encryption = config.getBoolean(s"$path.encryption")
    val filterTimeInSeconds = config.getInt(s"$path.filter-time-in-seconds")
  }

  val pingEndpoint = config.getString("ping-endpoint")

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

  val mqtt = new {
    private val path = "mqtt"

    val broker = config.getString(s"$path.broker")
    val mqttDirectivesTopicTemplate = config.getString(s"$path.mqtt-directives-topic-template")
    val mqttUpgradeTopicTemplate = config.getString(s"$path.mqtt-upgrade-topic-template")
    val qos = config.getInt(s"$path.qos")
    val clientId = config.getString(s"$path.client-id")

    val sslConfiguration = if(config.hasPath(s"$path.ssl-configuration")) {
      Some(
        new SSLConfiguration(
          config.getString(s"$path.ssl-configuration.client-cert"),
          config.getString(s"$path.ssl-configuration.client-key"),
          config.getString(s"$path.ssl-configuration.broker-ca-certificate")
        )
      )
    } else {
      None
    }
  }

  val aws = new {
    private val path = "aws"
    val configBucket = config.getString(s"$path.config-bucket")
  }
}
