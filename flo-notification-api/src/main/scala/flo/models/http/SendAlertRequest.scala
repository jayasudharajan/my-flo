package flo.models.http

import com.flo.notification.sdk.model.TelemetrySnapshot

case class SendAlertRequest(
    macAddress: String,
    alarmId: Int,
    telemetry: Option[TelemetrySnapshot]
)

object SendAlertRequest {
  private val macAddress = "32l423743djd"

  val example = SendAlertRequest(
    macAddress,
    55,
    Some(
      TelemetrySnapshot.default
    )
  )
}
