package com.flo.notification.sdk.circe

import com.flo.Models.KafkaMessages.SmsMessage
import com.flo.notification.router.core.api.Sms
import com.flo.notification.sdk.circe
import com.flo.notification.sdk.conf.SmsConfig
import io.circe.syntax._

final private[sdk] class SerializeSms(smsConfig: SmsConfig) extends (Sms => String) {

  override def apply(sms: Sms): String = {
    import circe._

    val deliveryCallback = smsConfig.deliveryCallback
      .replace(":incidentId", sms.incidentId)
      .replace(":userId", sms.userId)

    val postDeliveryCallback = smsConfig.postDeliveryCallback
      .replace(":incidentId", sms.incidentId)
      .replace(":userId", sms.userId)

    val smsMessage = SmsMessage(
      sms.incidentId,
      sms.text,
      sms.phoneNumber,
      deliveryCallback,
      postDeliveryCallback
    )

    smsMessage.asJson.noSpaces
  }

}
