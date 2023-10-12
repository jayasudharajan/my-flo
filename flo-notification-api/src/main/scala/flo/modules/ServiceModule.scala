package flo.modules

import java.util.concurrent.Executors

import com.flo.mqtt.{MQTTClient, MQTTSecurityProvider}
import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.communication.AsyncKafkaProducer
import com.flo.notification.sdk.service.NotificationService
import com.google.inject.Provides
import com.twitter.inject.TwitterModule
import flo.services.{AlarmCache, AlarmCacheUpdater, LocalizationService, TwilioConfig}
import flo.util.ConfigUtils
import javax.inject.Singleton

import scala.concurrent.ExecutionContext

object ServiceModule extends TwitterModule {

  @Singleton
  @Provides
  def providesNotificationService(implicit ec: ExecutionContext,
                                  as: ActorSystem,
                                  am: ActorMaterializer): NotificationService = {

    val executionContext   = ExecutionContext.fromExecutorService(Executors.newCachedThreadPool())
    val asyncKafkaProducer = new AsyncKafkaProducer(ConfigUtils.kafka.host)(executionContext)

    val mqttSecurity = ConfigUtils.mqtt.sslConfiguration.map { sslConfig =>
      new MQTTSecurityProvider(ConfigUtils.aws.configBucket, sslConfig)
    }

    val mqttClient = new MQTTClient(
      ConfigUtils.mqtt.broker,
      ConfigUtils.mqtt.qos,
      ConfigUtils.mqtt.clientId,
      mqttSecurity
    )

    new NotificationService(
      asyncKafkaProducer,
      Some(ConfigUtils.kafka.incidentTopic),
      Some(ConfigUtils.kafka.entityActivityTopic),
      mqttClient,
      ConfigUtils.databaseConfig,
      ConfigUtils.redisConfig,
      ConfigUtils.fireWriterBaseUrl
    )
  }

  @Singleton
  @Provides
  def providesAlarmCache(notificationService: NotificationService,
                         localizationService: LocalizationService): AlarmCache = {
    val executionContext  = ExecutionContext.fromExecutorService(Executors.newFixedThreadPool(2))
    val alarmCacheUpdater = new AlarmCacheUpdater(notificationService, localizationService)(executionContext)
    alarmCacheUpdater.run()
    alarmCacheUpdater
  }

  @Singleton
  @Provides
  def providesTwilioConfig(): TwilioConfig = ConfigUtils.twilioConfig
}
