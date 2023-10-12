package com.flo.notification.sdk.circe

import com.flo.Models.KafkaMessages.EmailFeatherMessage
import argonaut.Argonaut._

final private[sdk] class SerializeEmail extends (EmailFeatherMessage => String) {

  override def apply(email: EmailFeatherMessage): String =
    email.asJson.nospaces

}
