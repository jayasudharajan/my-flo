package com.flo.notification.kafka

import java.util.concurrent.TimeUnit

import akka.actor.{ActorSystem, Props}
import akka.kafka.{ConsumerSettings, ProducerSettings, Subscriptions}
import akka.stream.ActorMaterializer
import com.flo.notification.kafka.circe.DeserializeEntityActivity
import com.flo.notification.kafka.conf.KafkaConfig
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.delivery.KafkaSender
import com.typesafe.config.Config

import scala.concurrent.ExecutionContext

trait Module {

  // Requires
  def rootConfig: Config
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorMaterializer: ActorMaterializer
  def deserializeAlarmIncident: String => AlarmIncident
  def deserializeAlert: String => Alert
  def serializeAlarmIncident: AlarmIncident => String
  def actorSystem: ActorSystem

  // Privates
  private val kafkaConfig                  = appConfig.as[KafkaConfig]("kafka")
  private val alarmIncidentConsumerConfig  = kafkaConfig.alarmIncidentConsumer
  private val alertStatusConsumerConfig    = kafkaConfig.alertStatusConsumer
  private val entityActivityConsumerConfig = kafkaConfig.entityActivityConsumer

  private val consumerConfig = rootConfig.getConfig("akka.kafka.consumer")
  private val alarmIncidentConsumerSettings =
    ConsumerSettings[String, String](consumerConfig, None, None)
      .withBootstrapServers(kafkaConfig.hosts)
      .withGroupId(alarmIncidentConsumerConfig.groupId)
      .withPollTimeout(alarmIncidentConsumerConfig.pollTimeout)
      .withProperties(
        Map(
          "session.timeout.ms" -> 30000.toString,
          "max.poll.records"   -> 100.toString,
          "enable.auto.commit" -> false.toString
        )
      )

  private val alertStatusConsumerSettings =
    ConsumerSettings[String, String](consumerConfig, None, None)
      .withBootstrapServers(kafkaConfig.hosts)
      .withGroupId(alertStatusConsumerConfig.groupId)
      .withPollTimeout(alertStatusConsumerConfig.pollTimeout)
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

  private val rebalanceListener = actorSystem.actorOf(Props(new RebalanceListener))

  private val alarmIncidentSubscription = Subscriptions
    .topics(Set(alarmIncidentConsumerConfig.topic))
    .withRebalanceListener(rebalanceListener)

  private val alertStatusSubscription = Subscriptions.topics(Set(alertStatusConsumerConfig.topic))

  private val entityActivitySubscription = Subscriptions.topics(Set(entityActivityConsumerConfig.topic))

  private val producerConfig = rootConfig.getConfig("akka.kafka.producer")
  private val producerSettings = ProducerSettings[String, String](producerConfig, None, None)
    .withBootstrapServers(kafkaConfig.hosts)
  private val kafkaProducer = producerSettings.createKafkaProducer()

  sys.addShutdownHook {
    // TODO: Make this configurable?
    kafkaProducer.flush()
    kafkaProducer.close(10, TimeUnit.SECONDS)
  }

  // Provides
  val alarmIncidentConsumer: Consumer[AlarmIncidentProcessor] =
    new AlarmIncidentKafkaConsumer(
      alarmIncidentConsumerSettings,
      alarmIncidentSubscription,
      alarmIncidentConsumerConfig.parallelism,
      deserializeAlarmIncident
    )(defaultExecutionContext, actorMaterializer)

  val alertStatusConsumer: Consumer[AlertStatusProcessor] =
    new AlertStatusKafkaConsumer(
      alertStatusConsumerSettings,
      alertStatusSubscription,
      alertStatusConsumerConfig.parallelism,
      deserializeAlert
    )(defaultExecutionContext, actorMaterializer)

  val entityActivityConsumer: Consumer[EntityActivityProcessor] =
    new EntityActivityKafkaConsumer(
      entityActivityConsumerSettings,
      entityActivitySubscription,
      entityActivityConsumerConfig.parallelism,
      new DeserializeEntityActivity
    )(defaultExecutionContext, actorMaterializer)

  val sendToKafka: KafkaSender =
    new SendToKafka(producerSettings, kafkaProducer)(defaultExecutionContext, actorMaterializer)
}
