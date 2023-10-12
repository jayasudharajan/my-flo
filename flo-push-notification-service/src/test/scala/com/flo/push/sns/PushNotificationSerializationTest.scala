package com.flo.push.sns

import com.flo.push.aws.sns.circe._
import com.flo.push.aws.sns._
import com.flo.push.core.api.PushNotification
import com.flo.{FixtureReader, SyncTest}
import io.circe._
import io.circe.syntax._
import io.circe.parser.decode

class PushNotificationSerializationTest extends SyncTest with FixtureReader {

  val pushNotification = PushNotification(
    requestId = "f6029a48-4f64-484d-b5e7-18355e00aac4",
    userId = "f6029a48-4f64-484d-b5e7-18355e00aac5",
    deviceId = "f6029a48-4f64-484d-b5e7-18355e00aac6",
    title = "Push Title",
    body = "Push Body",
    tag = "Push Tag",
    color = "Push Color",
    clickAction = "Push Action",
    metadata = decode[Json]("""{"notification":{"alarm_id":11,"name":"high_water_usage","severity":1,"description":"Alarm Description 11"},"icd":{"device_id":"606405c0d2db","time_zone":"","system_mode":2,"icd_id":"00977ce3-6870-441f-8792-0bca4b8c0400"},"ts":1567449046249,"version":1,"id":"f6029a48-4f64-484d-b5e7-18355e00aac4"}""").getOrElse(Json.fromJsonObject(JsonObject.empty))
  )

  "Push Notification Serialization" - {

    "should serialize an Android Push Notification" in {
      val notification = Notification(pushNotification.title, pushNotification.body, pushNotification.tag, pushNotification.color, pushNotification.clickAction)
      val data = Data(pushNotification.metadata)
      val androidNotificationStr = AndroidNotification(notification, data).asJson.noSpaces
      val androidPushNotification = AndroidPushNotification(androidNotificationStr)
      val message = AwsPushMessageConfig(androidPushNotification.asJson).asJson.noSpaces

      message shouldEqual """{"Message":{"GCM":"{\"notification\":{\"title\":\"Push Title\",\"body\":\"Push Body\",\"tag\":\"Push Tag\",\"color\":\"Push Color\",\"click_action\":\"Push Action\",\"sound\":\"default\"},\"data\":{\"FloAlarmNotification\":{\"notification\":{\"alarm_id\":11,\"name\":\"high_water_usage\",\"severity\":1,\"description\":\"Alarm Description 11\"},\"icd\":{\"device_id\":\"606405c0d2db\",\"time_zone\":\"\",\"system_mode\":2,\"icd_id\":\"00977ce3-6870-441f-8792-0bca4b8c0400\"},\"ts\":1567449046249,\"version\":1,\"id\":\"f6029a48-4f64-484d-b5e7-18355e00aac4\"}}}"}}"""
    }

    "should serialize an iOS Push Notification" in {
      val iosNotification = IosNotification(pushNotification.body, Category(pushNotification.metadata))
      val iosNotificationContainer = IosNotificationContainer(iosNotification)
      val iosNotificationContainerStr = iosNotificationContainer.asJson.noSpaces
      val iosNotificationJson = IosPushNotification(iosNotificationContainerStr).asJson
      val message = AwsPushMessageConfig(iosNotificationJson).asJson.noSpaces

      message shouldEqual """{"Message":{"APNS":"{\"aps\":{\"alert\":\"Push Body\",\"category\":{\"FloAlarmNotification\":{\"notification\":{\"alarm_id\":11,\"name\":\"high_water_usage\",\"severity\":1,\"description\":\"Alarm Description 11\"},\"icd\":{\"device_id\":\"606405c0d2db\",\"time_zone\":\"\",\"system_mode\":2,\"icd_id\":\"00977ce3-6870-441f-8792-0bca4b8c0400\"},\"ts\":1567449046249,\"version\":1,\"id\":\"f6029a48-4f64-484d-b5e7-18355e00aac4\"}},\"sound\":\"default\"}}"}}"""
    }

    "should serialize an iOS Sandbox Push Notification" in {
      val iosNotification = IosNotification(pushNotification.body, Category(pushNotification.metadata))
      val iosNotificationContainer = IosNotificationContainer(iosNotification)
      val iosNotificationContainerStr = iosNotificationContainer.asJson.noSpaces
      val iosNotificationJson = IosSandboxPushNotification(iosNotificationContainerStr).asJson
      val message = AwsPushMessageConfig(iosNotificationJson).asJson.noSpaces

      message shouldEqual """{"Message":{"APNS_SANDBOX":"{\"aps\":{\"alert\":\"Push Body\",\"category\":{\"FloAlarmNotification\":{\"notification\":{\"alarm_id\":11,\"name\":\"high_water_usage\",\"severity\":1,\"description\":\"Alarm Description 11\"},\"icd\":{\"device_id\":\"606405c0d2db\",\"time_zone\":\"\",\"system_mode\":2,\"icd_id\":\"00977ce3-6870-441f-8792-0bca4b8c0400\"},\"ts\":1567449046249,\"version\":1,\"id\":\"f6029a48-4f64-484d-b5e7-18355e00aac4\"}},\"sound\":\"default\"}}"}}"""
    }
  }


}
