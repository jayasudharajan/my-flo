package com.flo.notification.sdk.model

import java.util.UUID

// TODO: Design this properly. Enforce that either deviceId or locationId are present.
case class AlarmDeliverySettings(
  deviceId: Option[UUID],
  locationId: Option[UUID],
  alarmId: Int,
  systemMode: Int,
  settings: DeliverySettings,
  isMuted: Boolean = false
)