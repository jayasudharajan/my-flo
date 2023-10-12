package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

case class ActionsTaken (
    id: Int,
    alarmId: Int,
    icdId: UUID,
    userId: UUID,
    actionId: Int,
    lastEventId: UUID,
    action: Int,
    expiresAt: LocalDateTime,
    updatedAt: LocalDateTime,
    createdAt: LocalDateTime
)
