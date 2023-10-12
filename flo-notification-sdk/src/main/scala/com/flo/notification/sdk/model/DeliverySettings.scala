package com.flo.notification.sdk.model

import io.getquill.Embedded

case class DeliverySettings(
    smsEnabled: Option[Boolean],
    emailEnabled: Option[Boolean],
    pushEnabled: Option[Boolean],
    callEnabled: Option[Boolean]
) extends Embedded
