package com.flo.puck.core.api

import java.time.LocalDateTime

case class AlarmEvent(
                       id: EventId,
                       deviceId: DeviceId,
                       createAt: LocalDateTime,
                       updateAt: LocalDateTime,
                       systemMode: SystemMode,
                       alarm: Alarm,
                       status: AlertState,
                       rawFwPayload: Json,
)
