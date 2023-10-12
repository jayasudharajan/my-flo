package com.flo.push.kafka.circe

import com.flo.push.core.api.PushNotification
import io.circe.parser.decode

final private[kafka] class DeserializePushNotification extends (String => PushNotification) {
  override def apply(pushNotificationStr: String): PushNotification = {

    decode[PushNotification](pushNotificationStr) match {
      case Right(pushNotification) => pushNotification
      case Left(error) => throw error
    }
  }

}
