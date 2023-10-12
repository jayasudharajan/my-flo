package com.flo.push.aws

package object sns {
  case class AwsPushMessageConfig(message: io.circe.Json)

  case class AndroidNotification(notification: Notification, data: Data)
  case class Data(floAlarmNotification: io.circe.Json)
  case class Notification(title: String, body: String, tag: String, color: String, clickAction: String, sound: String = "default")
  case class AndroidPushNotification(gcm: String)


  case class IosNotificationContainer(aps: IosNotification)
  case class Category(floAlarmNotification: io.circe.Json)
  case class IosNotification(alert: String, category: Category, sound: String = "default")

  case class IosPushNotification(apns: String)
  case class IosSandboxPushNotification(apnsSandbox: String)
}
