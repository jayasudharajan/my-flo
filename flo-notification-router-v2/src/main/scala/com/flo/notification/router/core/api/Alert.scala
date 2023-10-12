package com.flo.notification.router.core.api

import com.flo.notification.router.core.api.alert.AlertStatus

case class Alert(timestamp: Long,
                 macAddress: MacAddress,
                 systemMode: Int,
                 alarmId: AlarmId,
                 status: AlertStatus,
                 metadata: Option[AlarmIncidentMetadata],
                 telemetrySnapshot: TelemetrySnapshot,
                 raw: Option[Json])
