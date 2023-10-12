package com.flo.puck.kafka

import java.util.concurrent.TimeUnit

import akka.actor.ActorSystem
import akka.kafka.{ConsumerSettings, ProducerSettings, Subscriptions}
import com.flo.notification.kafka.SendToKafka
import com.typesafe.config.Config
import com.flo.puck.kafka.conf.KafkaConfig
import com.flo.puck.conf._
import com.flo.puck.core.api.{AlarmStateSender, Consumer, EntityActivityProcessor, PuckTelemetryProcessor}
import com.flo.puck.kafka.circe.{DeserializeEntityActivity, DeserializeTelemetryPuck, SerializeAlarmNotificationStatus}
import com.flo.puck.kafka.nrv2.AlarmStatusAdapter

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def rootConfig: Config
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def generateUuid: String

  // Privates
  private val kafkaConfig                  = appConfig.as[KafkaConfig]("kafka")
  private val puckTelemetryConsumerConfig  = kafkaConfig.puckTelemetryConsumer
  private val entityActivityConsumerConfig  = kafkaConfig.entityActivityConsumer

  private val puckTelemetrySubscription = Subscriptions.topics(Set(puckTelemetryConsumerConfig.topic))
  private val entityActivitySubscription = Subscriptions.topics(Set(entityActivityConsumerConfig.topic))
  private val consumerConfig = rootConfig.getConfig("akka.kafka.consumer")


  private val producerConfig = rootConfig.getConfig("akka.kafka.producer")
  private val producerSettings = ProducerSettings[String, String](producerConfig, None, None)
    .withBootstrapServers(kafkaConfig.hosts)
  private val kafkaProducer = producerSettings.createKafkaProducer()

  sys.addShutdownHook {
    // TODO: Make this configurable?
    kafkaProducer.flush()
    kafkaProducer.close(10, TimeUnit.SECONDS)
  }

  private val sendToKafka = new SendToKafka(producerSettings, kafkaProducer)(defaultExecutionContext, actorSystem)

  private val puckTelemetryConsumerSettings =
    ConsumerSettings[String, String](consumerConfig, None, None)
      .withBootstrapServers(kafkaConfig.hosts)
      .withGroupId(puckTelemetryConsumerConfig.groupId)
      .withPollTimeout(puckTelemetryConsumerConfig.pollTimeout)
      .withProperties(
        Map(
          "session.timeout.ms" -> 30000.toString,
          "max.poll.records"   -> 100.toString,
          "enable.auto.commit" -> false.toString
        )
      )
  private val entityActivityConsumerSettings =
    ConsumerSettings[String, String](consumerConfig, None, None)
      .withBootstrapServers(kafkaConfig.hosts)
      .withGroupId(entityActivityConsumerConfig.groupId)
      .withPollTimeout(entityActivityConsumerConfig.pollTimeout)
      .withProperties(
        Map(
          "session.timeout.ms" -> 30000.toString,
          "max.poll.records"   -> 100.toString,
          "enable.auto.commit" -> false.toString
        )
      )

  // Provides
  val puckTelemetryConsumer: Consumer[PuckTelemetryProcessor] =
    new PuckTelemetryKafkaConsumer(
      puckTelemetryConsumerSettings,
      puckTelemetrySubscription,
      puckTelemetryConsumerConfig.parallelism,
      new DeserializeTelemetryPuck
    )(defaultExecutionContext, actorSystem)

  val entityActivityConsumer: Consumer[EntityActivityProcessor] =
    new EntityActivityKafkaConsumer(
      entityActivityConsumerSettings,
      entityActivitySubscription,
      entityActivityConsumerConfig.parallelism,
      new DeserializeEntityActivity
    )(defaultExecutionContext, actorSystem)

  val sendAlarmState: AlarmStateSender = (macAddress, event) => {
    val serializer = new SerializeAlarmNotificationStatus
    val adapter = new AlarmStatusAdapter(generateUuid)
    val message = serializer(adapter(event, macAddress))
    sendToKafka(kafkaConfig.alertStatusProducer.topic, message)
  }
}
