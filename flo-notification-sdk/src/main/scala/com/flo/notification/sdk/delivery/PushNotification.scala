package com.flo.notification.sdk.delivery

case class PushNotification(
                             requestId: String,
                             userId: String,
                             deviceId: String,
                             title: String,
                             body: String,
                             tag: String,
                             color: String,
                             clickAction: String,
                             metadata: Map[String, Any]
                           )