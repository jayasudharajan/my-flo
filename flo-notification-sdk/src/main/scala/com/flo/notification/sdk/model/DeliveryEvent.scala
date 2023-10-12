package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

case class DeliveryEvent(
  id: UUID,
  alarmEventId: UUID,
  externalId: String,
  medium: Int,
  status: Int,
  info: Map[String, Any],
  userId: UUID,
  updateAt: LocalDateTime,
  createAt: LocalDateTime
)
