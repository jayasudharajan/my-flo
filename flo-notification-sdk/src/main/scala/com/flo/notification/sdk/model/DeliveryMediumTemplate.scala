package com.flo.notification.sdk.model

case class DeliveryMediumTemplate (
    id: Int,
    alarmId: Int,
    deliveryMediumId: Int,
    subject: Option[String],
    body: String
)
