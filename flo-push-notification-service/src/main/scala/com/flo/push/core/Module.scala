package com.flo.push.core

import com.flo.push.conf._
import com.flo.push.core.api.{MarkAsSent, NotificationTokenRetriever, PushNotificationConsumer, PushNotificationPlatformProcessor, PushNotificationProcessor, PushNotificationSender, ResourceName, ResourceNameRegistrator}
import com.typesafe.config.Config

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def pushNotificationConsumer: PushNotificationConsumer
  def registerResourceName: ResourceNameRegistrator
  def androidResourceName: ResourceName
  def iosResourceName: ResourceName
  def retrieveNotificationTokens: NotificationTokenRetriever
  def sendAndroidPushNotification: PushNotificationSender
  def sendIosPushNotification: PushNotificationSender
  def markNotificationAsSent: MarkAsSent

  // Private
  private val pushNotificationServiceEnabled = appConfig.as[Boolean]("enabled")

  private val processAndroidNotification: PushNotificationPlatformProcessor =
    new ProcessPlatformNotification(registerResourceName, androidResourceName, sendAndroidPushNotification)(defaultExecutionContext)

  private val processIosNotification: PushNotificationPlatformProcessor =
    new ProcessPlatformNotification(registerResourceName, iosResourceName, sendIosPushNotification)(defaultExecutionContext)

  private val processPushNotification: PushNotificationProcessor =
    new ProcessPushNotification(retrieveNotificationTokens,
      processAndroidNotification, processIosNotification, markNotificationAsSent)(defaultExecutionContext)

  if (pushNotificationServiceEnabled) {
    pushNotificationConsumer.start(processPushNotification)

    sys.addShutdownHook {
      pushNotificationConsumer.stop()
    }
  }
}
