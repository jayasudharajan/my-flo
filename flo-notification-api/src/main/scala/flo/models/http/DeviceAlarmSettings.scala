package flo.models.http

import com.flo.notification.sdk.model._
import com.twitter.finatra.validation.UUID

case class DeviceAlarmSettings(
    @UUID deviceId: String,
    settings: Option[List[AlarmConfig]],
    floSenseLevel: Option[Int],
    smallDripSensitivity: Option[Int],
    userDefined: Option[List[AlarmConfig]] = None
)

case class BatchDeviceAlarmSettings(items: Seq[DeviceAlarmSettings])

object DeviceAlarmSettings {
  val example = DeviceAlarmSettings(
    "873f6a8a-5ec0-4602-a245-909c45f76ea7",
    None,
    Some(5),
    Some(1)
  )

  def build(alertSettings: List[AlertSettings],
            userAlarmSettings: List[UserAlarmSettings],
            userDefined: Option[List[AlertSettings]] = None): List[DeviceAlarmSettings] = {

    val userAlarmSettingsMap   = userAlarmSettings.groupBy(_.icdId)
    val userDefinedSettingsMap = userDefined.map(_.groupBy(_.deviceId)).getOrElse(Map())

    alertSettings
      .groupBy(_.deviceId)
      .map {
        case (deviceId, settings) =>
          val setting = userAlarmSettingsMap.getOrElse(deviceId.get, Nil).headOption

          DeviceAlarmSettings(
            deviceId.get.toString,
            Some(AlarmConfig.fromAlertSettings(settings)),
            setting.flatMap(_.floSenseLevel),
            setting.flatMap(_.smallDripSensitivity),
            userDefinedSettingsMap.get(deviceId).map(AlarmConfig.fromAlertSettings)
          )
      }
      .toList
  }
}
