package com.flo.notification.sdk.model

import java.util.UUID

case class GroupRoleDeliverySettings(
                                 id: UUID,
                                 groupId: UUID,
                                 role: String,
                                 alarmSystemModeSettingsId: Int,
                                 settings: DeliverySettings
                               )
