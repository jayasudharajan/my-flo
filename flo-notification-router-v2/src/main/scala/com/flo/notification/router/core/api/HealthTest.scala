package com.flo.notification.router.core.api

import java.time.LocalDateTime
import java.util.UUID

sealed trait HealthTestType
case object AutoHealthTest   extends HealthTestType
case object ManualHealthTest extends HealthTestType

case class HealthTest(roundId: UUID, deviceId: String, `type`: HealthTestType, created: LocalDateTime)
