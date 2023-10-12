package com.flo.puck.kafka.circe

import com.flo.puck.core.api.activity.EntityActivity
import io.circe.parser.decode

final private[kafka] class DeserializeEntityActivity extends (String => EntityActivity) {
  override def apply(entityActivityStr: String): EntityActivity = {

    decode[EntityActivity](entityActivityStr) match {
      case Right(entityActivity) => entityActivity
      case Left(error) => throw error
    }
  }
}
