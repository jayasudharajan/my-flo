package com.flo.push.kafka

import akka.actor.ActorSystem
import akka.kafka.{CommitterSettings, ConsumerSettings, Subscriptions}
import akka.stream.ActorMaterializer
import com.flo.push.conf._
import com.flo.push.core.api.PushNotificationConsumer
import com.flo.push.kafka.circe.DeserializePushNotification
import com.flo.push.kafka.conf.ConsumerConfig
import com.typesafe.config.Config

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def rootConfig: Config
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer

  // Private
  private val pushNotificationConsumerConfig = appConfig.as[ConsumerConfig]("consumer")
  private val consumerConfig = rootConfig.getConfig("akka.kafka.consumer")
  private val consumerSettings =
    ConsumerSettings[String, String](consumerConfig, None, None)
      .withBootstrapServers(pushNotificationConsumerConfig.hosts)
      .withGroupId(pushNotificationConsumerConfig.groupId)
      .withPollTimeout(pushNotificationConsumerConfig.pollTimeout)

  private val committerConfig   = rootConfig.getConfig("akka.kafka.committer")
  private val committerSettings = CommitterSettings(committerConfig)

  private val subscription = Subscriptions.topics(Set(pushNotificationConsumerConfig.topic))

  private val deserializePushNotification = new DeserializePushNotification

  // Provides
  val pushNotificationConsumer: PushNotificationConsumer = new ConsumePushNotifications(
    consumerSettings,
    committerSettings,
    subscription,
    deserializePushNotification,
    pushNotificationConsumerConfig.parallelism)(defaultExecutionContext, actorMaterializer)
}
