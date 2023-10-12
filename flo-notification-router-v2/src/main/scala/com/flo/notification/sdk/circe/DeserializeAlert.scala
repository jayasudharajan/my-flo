package com.flo.notification.sdk.circe

import com.flo.notification.router.core.api.Alert
import com.flo.notification.sdk.circe
import io.circe.parser.decode

final private[sdk] class DeserializeAlert extends (String => Alert) {

  override def apply(alertStr: String): Alert = {
    import circe._

    decode[Alert](alertStr) match {
      case Right(alert) => alert
      case Left(error)  => throw error
    }
  }

}
