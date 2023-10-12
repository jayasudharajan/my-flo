package com.flo.push.kafka

import com.flo.push.core.api.PushNotification
import io.circe.Decoder
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.deriveConfiguredDecoder

package object circe {
  private implicit val customConfig: Configuration = Configuration.default.withDefaults.withSnakeCaseMemberNames

  implicit val pushNotificationDecoder: Decoder[PushNotification] = deriveConfiguredDecoder
}
