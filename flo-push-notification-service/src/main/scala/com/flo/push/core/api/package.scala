package com.flo.push.core

import scala.concurrent.Future

package object api {
  type Metadata = io.circe.Json
  type UserId   = String
  type DeviceId = String
  type PlatformResourceName = String
  type Token = String
  type ResourceName = String
  type IncidentId = String

  type PushNotificationSender            = (PushNotification, ResourceName) => Future[Unit]
  type PushNotificationPlatformProcessor = (PushNotification, Token) => Future[Unit]
  type PushNotificationProcessor         = PushNotification => Future[Unit]
  type PushNotificationConsumer          = Consumer[PushNotificationProcessor]
  type NotificationTokenRetriever        = UserId => Future[UserNotificationTokens]
  type MarkAsSent                   = (UserId, IncidentId) => Future[Unit]

  type ResourceNameRegistrator = (UserId, DeviceId, PlatformResourceName, Token) => Future[ResourceName]
}
