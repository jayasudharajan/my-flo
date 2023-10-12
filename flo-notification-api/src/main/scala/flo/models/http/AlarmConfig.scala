package flo.models.http

import com.flo.notification.sdk.model.{AlertSettings, SystemMode}

case class AlarmConfig(
    alarmId: Int,
    systemMode: String,
    smsEnabled: Option[Boolean],
    emailEnabled: Option[Boolean],
    pushEnabled: Option[Boolean],
    callEnabled: Option[Boolean],
    isMuted: Option[Boolean]
)

object AlarmConfig {
  def fromAlertSettings(settings: List[AlertSettings]): List[AlarmConfig] =
    settings
      .map(
        x =>
          AlarmConfig(
            x.alarmId,
            SystemMode.toString(x.systemMode),
            x.settings.smsEnabled,
            x.settings.emailEnabled,
            x.settings.pushEnabled,
            x.settings.callEnabled,
            Some(x.isMuted)
        )
      )
}
