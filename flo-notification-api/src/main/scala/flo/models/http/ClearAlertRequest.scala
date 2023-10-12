package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class ClearAlertsRequest(
    alarmIds: List[Int],
    @UUID locationId: Option[String],
    @UUID userId: Option[String],
    devices: List[DeviceInfo],
    snoozeSeconds: Int
)

case class ClearAlertsBody(
    alarmIds: List[Int],
    @UUID locationId: Option[String],
    devices: List[DeviceInfo],
    snoozeSeconds: Int
)

case class ClearAlertRequest(
    @RouteParam alarmId: Int,
    @UUID locationId: Option[String],
    @UUID userId: Option[String],
    devices: List[DeviceInfo],
    snoozeSeconds: Int
)

case class ClearAlertBody(
    @UUID locationId: Option[String],
    devices: List[DeviceInfo],
    snoozeSeconds: Int
)

case class DeviceInfo(
    @UUID id: String,
    macAddress: String
)
