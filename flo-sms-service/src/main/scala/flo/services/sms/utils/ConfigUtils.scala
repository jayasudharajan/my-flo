package flo.services.sms.utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory

object ConfigUtils {

  val config = ConfigFactory.load()
  
  val twilio = new {
    private val twilioConfig = config.getConfig("twilio")
    val accountSID = twilioConfig.getString("accountSID")
    val authToken = twilioConfig.getString("authToken")
    val fromNumber = twilioConfig.getString("fromNumber")
  }

  val kafka = new {
    private val kafkaConfig = config.getConfig("kafka")
    val host = kafkaConfig.getString("host")
    val groupId = kafkaConfig.getString("group-id")
    val topic = kafkaConfig.getString("topic")
    val consumerName = kafkaConfig.getString("consumer-name")
    val filterTimeInSeconds = kafkaConfig.getInt("filter-time-in-seconds")
    val maxPollRecords = kafkaConfig.getLong("max-poll-records")
    val pollTimeout = kafkaConfig.getLong("poll-timeout")
    val encryption = kafkaConfig.getBoolean("encryption")
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
}
