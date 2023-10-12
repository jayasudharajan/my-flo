package com.flo.notification.sdk.model

import java.util.UUID

case class UserDeliverySettings(
    id: UUID,
    userId: UUID,
    icdId: UUID,
    locationId: UUID,
    alarmSystemModeSettingsId: Int,
    settings: DeliverySettings,
    isMuted: Boolean = false
)