package com.flo.notification.sdk.model

import java.util.UUID

case class GroupRoleAlertSettings (
                           groupId: UUID,
                           role: String,
                           alarmId: Int,
                           name: String,
                           severity: Int,
                           systemMode: Int,
                           settings: DeliverySettings
                         )
