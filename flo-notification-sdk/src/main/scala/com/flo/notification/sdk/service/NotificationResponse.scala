package com.flo.notification.sdk.service

case class NotificationResponse(
                                 id: String,
                                 time: String,
                                 alarmId: Int,
                                 systemMode: Int,
                                 ackTopic: String,
                                 actions: List[NotificationResponseAction]
                               )
