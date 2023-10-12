package com.flo.puck.kafka.circe

import com.flo.puck.core.api.PuckTelemetry
import com.flo.puck.kafka.circe
import io.circe.parser.decode

final private[kafka] class DeserializeTelemetryPuck extends (String => PuckTelemetry) {
  override def apply(puckTelemetryStr: String): PuckTelemetry = {

    import circe._

    decode[PuckTelemetry](puckTelemetryStr) match {
      case Right(puckTelemetry)   => puckTelemetry
      case Left(error)            => throw error
    }
  }
}
