package flo.util

import com.flo.mqtt.SSLConfiguration
import com.typesafe.config.ConfigFactory
import flo.services.TwilioConfig

object ConfigUtils {
  val config = ConfigFactory.load()

  val finatra = new {
    private val finatra = config.getConfig("finatra")
    val httpsPort       = finatra.getString("httpsPort")
    val httpPort        = finatra.getString("httpPort")
  }

  val kafka = new {
    private val kafka       = config.getConfig("kafka")
    val host                = kafka.getString("host")
    val incidentTopic       = kafka.getString("incident-topic")
    val entityActivityTopic = kafka.getString("entity-activity-topic")
  }

  val mqtt = new {
    private val mqtt = config.getConfig("mqtt")

    val broker   = mqtt.getString("broker")
    val qos      = mqtt.getInt("qos")
    val clientId = mqtt.getString("client-id")

    val sslConfiguration = if (mqtt.hasPath("ssl-configuration")) {
      val sslConfiguration = mqtt.getConfig("ssl-configuration")

      Some(
        new SSLConfiguration(
          sslConfiguration.getString("client-cert"),
          sslConfiguration.getString("client-key"),
          sslConfiguration.getString("broker-ca-certificate")
        )
      )
    } else {
      None
    }
  }

  val aws = new {
    private val aws  = config.getConfig("aws")
    val configBucket = aws.getString("config-bucket")
  }

  val databaseConfig = config.getConfig("db-context")

  val redisConfig = config.getConfig("redis")

  val fireWriterBaseUrl = config.getString("flo.fire-writer.url")

  val twilioConfig = TwilioConfig(
    customerCarePhoneNumber = config.getString("twilio.customer-care-phone-number")
  )

  val randomizeFeedbackFlowOptions = config.getBoolean("api.randomize-feedback-flow-options")
  val randomizeUserFeedbackOptions = config.getBoolean("api.randomize-user-feedback-options")
}
