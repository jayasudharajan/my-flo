package Utils

import com.amazonaws.regions.{Region, Regions}
import com.typesafe.config.ConfigFactory

/**
  * Created by Francisco on 4/27/2016.
  */
object ApplicationSettings {
  private val configuration = ConfigFactory.load()

  val push = new {
    private val pushConfig = configuration.getConfig("push")

    val enabled = pushConfig.getBoolean("enabled")
  }

  val redis = new {
    private val redisConfig = configuration.getConfig("redis")

    val host = redisConfig.getString("host")
    val port = redisConfig.getInt("port")
  }

  object cs {
    lazy val email: Option[Int] = GetIntValue(Some("cs.email"))
    lazy val sleepModeAlertSet: Set[Int] = Set[Int](16)
  }

  object kafka {
    private val kafkaConfig = configuration.getConfig("kafka")

    lazy val groupId: Option[String] = GetStringValue(Some("kafka.group-id"))
    lazy val topic: Option[String] = GetStringValue(Some("kafka.topic"))
    lazy val emailProducerTopic: Option[String] = GetStringValue(Some("kafka.email-producer.topic"))
    lazy val emailProducerTopicV2: Option[String] = GetStringValue(Some("kafka.email-producer.topic-v2"))
    lazy val smsProducerTopic: Option[String] = GetStringValue(Some("kafka.sms-producer.topic"))
    lazy val alarmNotificationStatusTopic: Option[String] = GetStringValue(Some("kafka.alarm-notification-status.topic"))
    lazy val externalActionsValveStatusTopic: Option[String] = GetStringValue(Some("kafka.external-actions.valve-status.topic"))
    lazy val encryption = kafkaConfig.getBoolean("encryption")
    lazy val filterTimeInSeconds = kafkaConfig.getInt("filter-time-in-seconds")
    lazy val host: Option[String] = GetStringValue(Some("kafka.host"))
    lazy val maxPollRecords = kafkaConfig.getLong("max-poll-records")
    lazy val pollTimeout = kafkaConfig.getLong("poll-timeout")
    lazy val scheduledNotificationsTaskTopic = GetStringValue(Some("kafka.scheduled-notifications.scheduled-task.topic"))
    lazy val voiceTopic: Option[String] = GetStringValue(Some("kafka.voice-producer.topic"))
  }

  val cipher = new {
    private val cipherConfig = configuration.getConfig("cipher")

    val keyProvider = new {
      private val keyProviderConfig = cipherConfig.getConfig("key-provider")

      val bucketRegion = Region.getRegion(Regions.fromName(keyProviderConfig.getString("bucket-region")))
      val bucketName = keyProviderConfig.getString("bucket-name")
      val keyPathTemplate = keyProviderConfig.getString("key-path-template")
      val keyId = keyProviderConfig.getString("key-id")
    }
  }

  object floActors {

    object numberOfWorkers {
      lazy val applePushNotifications: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.apple-push-notifications"))
      lazy val androidPushNotifications: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.android-push-notifications"))
      lazy val decisionEngine: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.decision-engine"))
      lazy val kafkaReader: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.kafka-reader"))
      lazy val kafkaProducer: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.kafka-producer"))
      lazy val kafkaReaderExternalActions: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.kafka-reader-external-actions"))
      lazy val externalActions: Option[Int] = GetIntValue(Some("flo-actors.number-of-workers.external-actions"))
    }

  }

  object flo {

    object api {
      val url: Option[String] = GetStringValue(Some("flo.api.url"))
      val user: Option[String] = GetStringValue(Some("flo.api.user"))
      val token: Option[String] = GetStringValue(Some("flo.api.token"))

      object client {
        val id: Option[String] = GetStringValue(Some("flo.api.client.id"))
        val secret: Option[String] = GetStringValue(Some("flo.api.client.secret"))
      }

    }

    object sns {

      object apple {
        val defaultArn: Option[String] = GetStringValue(Some("flo.sns.apple.default-app-arn"))
      }

      object android {
        val defaultArn: Option[String] = GetStringValue(Some("flo.sns.android.default-app-arn"))
      }

    }

    object graveyardTime {
      val startsHourOfTheDay: Option[String] = GetStringValue(Some("flo.graveyard-time.starts-hour-of-the-day"))
      val endsHourOfTheDay: Option[String] = GetStringValue(Some("flo.graveyard-time.ends-hour-of-the-day"))
      val enabled: Boolean = if (GetIntValue(Some("flo.graveyard-time.enabled")).getOrElse(0) == 1) true else false
      val sendEmails: Boolean = if (GetIntValue(Some("flo.graveyard-time.send-emails")).getOrElse(0) == 1) true else false
      val sendSMS: Boolean = if (GetIntValue(Some("flo.graveyard-time.send-sms")).getOrElse(0) == 1) true else false
      val sendAppNotifications: Boolean = if (GetIntValue(Some("flo.graveyard-time.send-app-notifications")).getOrElse(0) == 1) true else false

    }

    object alarmSettings {
      lazy val especialTrashAlertsWithSleepModeDefinition: Set[Int] = Set[Int](35, 47, 36, 48, 38, 43, 44)
    }

    lazy val alertsWithSleepModeDefinitions: Set[Int] = Set[Int](33, 50, 46, 4, 32, 39, 40, 41, 42, 5, 34, 28, 31, 29, 30)
    lazy val floSenseDevices: Set[String] = Set[String]("587a622fab1f,606405bee6fc,606405c10f6d,606405c074ba,606405c074ba,606405c07641,606405c0b849,f045da306cd5,f045da30718a,606405c11e04,d436398cead2,c8df84579ea5,f045da2c8025,f045da30574f,f045da2c7e70,7c010a662cd2,38d269def5b1,10cea9130b4c,c8df8456a958,606405c075c0,606405c112f9,f045da301ecc")
  }


  private def GetStringValue(v: Option[String]): Option[String] = v match {
    case Some(key) =>
      if (key.nonEmpty) {
        val keyValue: Option[String] = sys.env.get(key.replace(".", "_").replace("-", "_").toUpperCase)

        if (keyValue.isDefined)
          keyValue
        else
          Some(configuration.getString(key))
      }
      else {
        None
      }
    case None => //None was sent so None is returned
      None
    case _ => // What was sent was not a string key
      None
  }

  private def GetIntValue(v: Option[String]): Option[Int] = v match {
    case Some(key) =>
      if (key.nonEmpty) {
        val keyValue: Option[String] = sys.env.get(key.replace(".", "_").replace("-", "_").toUpperCase)

        if (keyValue.isDefined)
          Some(keyValue.get.toInt)
        else
          Some(configuration.getInt(key))
      }
      else {
        None
      }
    case None => //None was sent so None is returned
      None
    case _ => // What was sent was not a string key
      None
  }

}
