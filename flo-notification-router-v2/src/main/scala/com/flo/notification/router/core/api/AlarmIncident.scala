package com.flo.notification.router.core.api

case class AlarmIncident(
    id: String,
    timestamp: Long,
    macAddress: String,
    systemMode: Int,
    alarmId: AlarmId,
    metadata: AlarmIncidentMetadata,
    snapshot: TelemetrySnapshot,
    raw: Option[Json],
    applicationType: Option[Int],
    resolvedAlarmIncident: Option[AlarmIncident] = None,
)
