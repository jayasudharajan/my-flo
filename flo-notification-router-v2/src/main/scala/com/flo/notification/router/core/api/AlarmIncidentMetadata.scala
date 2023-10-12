package com.flo.notification.router.core.api

import java.util.UUID

case class AlarmIncidentMetadata(
    roundId: Option[UUID],
    flosenseStrength: Option[Int],
    flosenseShutoffEnabled: Option[Boolean],
    shutoffEpochSec: Option[Int],
    inSchedule: Option[Boolean],
    flosenseShutoffLevel: Option[Int],
    shutoffTriggered: Option[Boolean]
)
