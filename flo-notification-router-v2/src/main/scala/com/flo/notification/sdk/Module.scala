package com.flo.notification.sdk

import java.time.Clock
import java.util.UUID

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.communication.AsyncKafkaProducer
import com.flo.mqtt.{MQTTClient, MQTTSecurityProvider, SSLConfiguration}
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api.{RegisterDeliveryMediumTriggered, _}
import com.flo.notification.sdk.circe._
import com.flo.notification.sdk.conf.{MqttConfig, SmsConfig}
import com.flo.notification.sdk.delivery.{DeliveryService, PushNotification}
import com.flo.notification.sdk.incident.IncidentService
import com.flo.notification.sdk.model.UserAlarmSettings
import com.flo.notification.sdk.service.NotificationService
import com.github.blemale.scaffeine.{Cache, Scaffeine}
import com.typesafe.config.Config

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

trait Module {

  // Requires
  def rootConfig: Config
  def appConfig: Config
  def blockableExecutionContext: ExecutionContext
  def defaultExecutionContext: ExecutionContext
  def generateUuid: String
  def toUuid(value: String): UUID
  def defaultClock: Clock
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer
  def retrieveLatestHealthTestResultByDeviceId: LatestHealthTestByDeviceIdRetriever
  def retrieveHierarchyAwareDeliverySettings: (UserId, DeviceId) => Future[Seq[AlarmSystemModeDeliverySettings]]

  // Privates
  private val smsConfig             = appConfig.as[SmsConfig]("sms")
  private val dbConfig: Config      = rootConfig.getConfig("postgres-db-context")
  private val redisConfig: Config   = rootConfig.getConfig("redis")
  private val fireWriterUrl: String = rootConfig.as[String]("fire-writer.url")
  private val mqttConfig            = rootConfig.as[MqttConfig]("mqtt")

  private val kafkaHosts                          = appConfig.as[String]("kafka.hosts")
  private val entityActivityProducerTopic: String = appConfig.as[String]("kafka.entity-activity-producer.topic")

  private val asyncKafkaProducer = new AsyncKafkaProducer(kafkaHosts)(blockableExecutionContext)

  private val mqttClient = new MQTTClient(
    mqttConfig.broker,
    mqttConfig.qos,
    mqttConfig.clientId,
    Some(
      new MQTTSecurityProvider(
        mqttConfig.sslConfiguration.awsConfigBucket,
        SSLConfiguration(
          mqttConfig.sslConfiguration.clientCert,
          mqttConfig.sslConfiguration.clientKey,
          mqttConfig.sslConfiguration.brokerCaCertificate
        )
      )
    )
  )

  sys.addShutdownHook {
    asyncKafkaProducer.close()
  }

  private val notificationService: NotificationService =
    new NotificationService(
      asyncKafkaProducer,
      None,
      Some(entityActivityProducerTopic),
      mqttClient,
      dbConfig,
      redisConfig,
      fireWriterUrl
    )(
      defaultExecutionContext,
      actorSystem,
      actorMaterializer
    )

  private val deliveryService: DeliveryService =
    new DeliveryService(notificationService, retrieveHierarchyAwareDeliverySettings)(defaultExecutionContext)

  private val incidentService: IncidentService =
    new incident.IncidentService(
      defaultClock,
      notificationService,
      retrieveLatestHealthTestResultByDeviceId,
      generateUuid
    )(defaultExecutionContext)

  private val userAlarmSettingsCache: Cache[(UserId, DeviceId), Option[UserAlarmSettings]] =
    Scaffeine()
      .recordStats()
      .expireAfterWrite(5.minutes)
      .maximumSize(5000)
      .build[(UserId, DeviceId), Option[UserAlarmSettings]]()

  // TODO: These serialization/deserialization instances are likely to belong to kafka package. Move them there.
  // Provides
  val deserializeAlert: String => Alert                     = new DeserializeAlert
  val deserializeAlarmIncident: String => AlarmIncident     = new DeserializeAlarmIncident
  val serializeAlarmIncident: AlarmIncident => String       = new SerializeAlarmIncident
  val serializeSms: Sms => String                           = new SerializeSms(smsConfig)
  val serializeEmail: EmailFeatherMessage => String         = new SerializeEmail
  val serializeVoiceCall: VoiceCall => String               = new SerializeVoiceCall
  val serializePushNotification: PushNotification => String = new SerializePushNotification

  val deserializationErrors: Set[Class[_ <: Throwable]] = Set(classOf[io.circe.Error])

  val retrieveDeliverySettings: DeliverySettingsRetriever             = deliveryService.retrieveDeliverySettings
  val retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever = deliveryService.retrieveDeliveryMediumTemplate
  val retrieveDoNotDisturbSettings: DoNotDisturbSettingsRetriever     = deliveryService.retrieveDoNotDisturbSettings

  val retrieveAlarm: AlarmRetriever = notificationService.getAlarm

  val registerDeliveryMediumTriggered: RegisterDeliveryMediumTriggered = incidentService.registerDeliveryMediumTriggered
  val registerIncident: RegisterIncident                               = incidentService.registerIncident
  val retrieveFrequencyCapExpiration: FrequencyCapExpirationRetriever  = incidentService.retrieveFrequencyCapExpiration
  val retrieveSnoozeTime: SnoozeTimeRetriever                          = incidentService.retrieveSnoozeTime
  val resolveHealthTestRelatedAlarms: HealthTestRelatedAlarmsResolver  = incidentService.resolveHealthTestRelatedAlarms
  val resolvePendingAlerts: PendingAlertResolver                       = incidentService.resolvePendingAlerts
  val resolvePendingAlertsForAlarm: PendingAlertsForAlarmResolver      = incidentService.resolvePendingAlerts
  val convertToAlarmIncident: AlarmIncidentConverter                   = incidentService.convertToAlarmIncident
  val cleanUpDeviceData: DeviceDataCleanUp                             = incidentService.cleanUpDeviceData

  val retrieveUserAlarmSettings: UserAlarmSettingsRetriever = (userId: UserId, deviceId: DeviceId) => {
    val cacheKey = (userId, deviceId)

    userAlarmSettingsCache.getIfPresent(cacheKey) match {
      case Some(settings) => Future.successful(settings)
      case None =>
        val settings = incidentService.getUserAlarmSettings(userId, deviceId)
        settings.foreach(userAlarmSettingsCache.put(cacheKey, _))(defaultExecutionContext)
        settings
    }
  }
}
