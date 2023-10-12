package com.flo.notification.sdk.model

import java.util.UUID

case class AlertDeliverySettings(userDefined: List[AlertSettings], userNonDefined: List[AlertSettings])

case class AlertSettings (
  deviceId: Option[UUID],
  locationId: Option[UUID],
  alarmId: Int,
  name: String,
  severity: Int,
  systemMode: Int,
  settings: DeliverySettings,
  isMuted: Boolean = false
)

object AlertSettings {
  private val nilUuid = new UUID(0, 0)

  def apply(deviceId: UUID, locationId: UUID, alarmId: Int, name: String, severity: Int, systemMode: Int, settings: DeliverySettings, isMuted: Boolean): AlertSettings = {
    val maybeDeviceId = if (deviceId == nilUuid) None else Some(deviceId)
    val maybeLocationId = if (locationId == nilUuid) None else Some(locationId)

    AlertSettings(maybeDeviceId, maybeLocationId, alarmId, name, severity, systemMode, settings, isMuted)
  }
}