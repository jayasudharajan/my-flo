package flo.models.http

import com.flo.notification.sdk.model.AlertSettings
import com.twitter.finatra.request.{QueryParam, RouteParam}
import com.twitter.finatra.validation.UUID

case class AlertSettingsRequest(
    @RouteParam @UUID userId: String,
    @QueryParam devices: String,
    @QueryParam accountType: String = "personal"
)

case class BatchAlertSettingsRequest(@RouteParam @UUID userId: String,
                                     deviceIds: Set[String] = Set(),
                                     locationIds: Set[String] = Set(),
                                     accountType: String = "personal")

case class BatchDeviceAlertSettingsResponse(items: Seq[DeviceAlarmSettings])

case class LocationAlertSettings(locationId: String, settings: List[AlarmConfig], userDefined: List[AlarmConfig])

case class BatchLocationAlertSettingsResponse(items: Seq[LocationAlertSettings])

object BatchLocationAlertSettingsResponse {
  def build(alertSettings: List[AlertSettings],
            userDefined: List[AlertSettings]): BatchLocationAlertSettingsResponse = {

    val groupedAlertSettings = alertSettings.groupBy(_.locationId)
    val groupedUserDefined   = userDefined.groupBy(_.locationId)

    BatchLocationAlertSettingsResponse(
      groupedAlertSettings.map {
        case (locationId, settings) =>
          LocationAlertSettings(
            locationId.get.toString,
            AlarmConfig.fromAlertSettings(settings),
            AlarmConfig.fromAlertSettings(groupedUserDefined.getOrElse(locationId, List()))
          )
      }.toList
    )
  }
}
