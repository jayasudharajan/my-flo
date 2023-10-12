package com.flo.notification.sdk.circe

import com.flo.notification.router.core.api.TelemetrySnapshot
import com.flo.notification.sdk.circe
import io.circe.parser.decode

final private[sdk] class DeserializeTelemetrySnapshot extends (String => TelemetrySnapshot) {
  override def apply(telemetrySnapshotStr: String): TelemetrySnapshot = {
    import circe._

    decode[TelemetrySnapshot](telemetrySnapshotStr) match {
      case Right(telemetrySnapshot) => telemetrySnapshot
      case Left(error)              => throw error
    }
  }
}
