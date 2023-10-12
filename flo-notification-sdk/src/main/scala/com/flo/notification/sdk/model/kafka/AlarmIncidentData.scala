package com.flo.notification.sdk.model.kafka

import com.flo.notification.sdk.model.TelemetrySnapshot

case class AlarmIncidentData(
                              alarm: AlarmIncidentAlarmInfo,
                              snapshot: Option[TelemetrySnapshot]
                            )
