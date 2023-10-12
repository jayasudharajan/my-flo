package flo.models.http

import java.util.UUID

import com.flo.notification.sdk.model.{AlarmDeliverySettings, DeliverySettings, SystemMode}
import com.twitter.finatra.request.RouteParam

case class SettingsRequest(deviceId: Option[String],
                           locationId: Option[String],
                           settings: Option[List[AlarmConfig]],
                           floSenseLevel: Option[Int],
                           smallDripSensitivity: Option[Int])

case class UpdateSettingsRequest(
    @RouteParam userId: String,
    items: List[SettingsRequest],
    accountType: String = "personal"
)

object UpdateSettingsRequest {
  def toAlarmDeliverySettings(updateSettingsRequest: UpdateSettingsRequest): List[AlarmDeliverySettings] =
    updateSettingsRequest.items.flatMap { alertSettings =>
      alertSettings.settings.getOrElse(List()).map { s =>
        AlarmDeliverySettings(
          alertSettings.deviceId.map(UUID.fromString),
          alertSettings.locationId.map(UUID.fromString),
          s.alarmId,
          SystemMode.fromString(s.systemMode),
          DeliverySettings(
            s.smsEnabled,
            s.emailEnabled,
            s.pushEnabled,
            s.callEnabled
          ),
          s.isMuted.getOrElse(false)
        )
      }
    }
}
