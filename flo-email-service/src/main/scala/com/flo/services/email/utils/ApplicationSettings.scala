package com.flo.services.email.utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory

object ApplicationSettings {


	private val config = ConfigFactory.load()

	lazy val kafka = new {
		lazy val groupId = config.getString("kafka.group-id")
		lazy val topic = config.getString("kafka.topic")
		lazy val topicV2 = config.getString("kafka.topic-v2")
		lazy val topicV3 = config.getString("kafka.topic-v3")
		lazy val consumerName = config.getString("kafka.consumer-name")
		lazy val filterTimeInSeconds = config.getInt("kafka.filter-time-in-seconds")
		lazy val encryption = config.getBoolean("kafka.encryption")
		lazy val maxPollRecords = config.getLong("kafka.max-poll-records")
		lazy val pollTimeout = config.getLong("kafka.poll-timeout")
		lazy val host = config.getString("kafka.host")

	}

	lazy val emailTemplates = new {
		lazy val alarmSeverityLow = config.getString("email-templates.alarm-severity-low")
		lazy val alarmSeverityMedium = config.getString("email-templates.alarm-severity-medium")
		lazy val alarmSeverityHigh = config.getString("email-templates.alarm-severity-high")
	}


	lazy val sendWithUs = new {
		lazy val name = "Flotechnologies"
		lazy val apiKey = config.getString("send-with-us.api-key")
		lazy val defaultEmailAddress = config.getString("send-with-us.default-email-address")
		lazy val replyToEmailAddress = config.getString("send-with-us.reply-to-email-address")
	}

	lazy val cipher = new {
		lazy private val cipherConfig = config.getConfig("cipher")

		lazy val keyProvider = new {
			lazy private val keyProviderConfig = cipherConfig.getConfig("key-provider")

			lazy val bucketRegion = Region.getRegion(Regions.fromName(keyProviderConfig.getString("bucket-region")))
			lazy val bucketName = keyProviderConfig.getString("bucket-name")
			lazy val keyPathTemplate = keyProviderConfig.getString("key-path-template")
			lazy val keyId = keyProviderConfig.getString("key-id")
		}
	}


}