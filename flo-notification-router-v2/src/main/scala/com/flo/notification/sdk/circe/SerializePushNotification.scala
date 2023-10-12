package com.flo.notification.sdk.circe

import com.flo.json4s.SimpleSerialization
import com.flo.notification.sdk.delivery.PushNotification

final private[sdk] class SerializePushNotification extends (PushNotification => String) with SimpleSerialization {

  override def apply(pushNotification: PushNotification): String =
    serializeToSnakeCase(pushNotification)

}
