package com.flo.puck.http.nrv2

case class AlarmIncident(
  macAddress: String,
  alarmId: AlarmId,
  telemetry: TelemetrySnapshot
)