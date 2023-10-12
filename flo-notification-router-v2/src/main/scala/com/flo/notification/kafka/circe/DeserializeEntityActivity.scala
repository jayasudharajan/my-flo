package com.flo.notification.kafka.circe

import com.flo.notification.router.core.api.activity.EntityActivity
import com.flo.notification.kafka.circe
import io.circe.parser.decode

final private[kafka] class DeserializeEntityActivity extends (String => EntityActivity) {
  override def apply(entityActivityStr: String): EntityActivity = {

    import circe._

    decode[EntityActivity](entityActivityStr) match {
      case Right(entityActivity) => entityActivity
      case Left(error)           => throw error
    }
  }
}
