package com.flo.notification.sdk.model.kafka

import java.util.UUID.randomUUID

import com.flo.notification.sdk.model.TelemetrySnapshot

//To snake case
case class AlarmIncident(
                          id: String,
                          ts: Long,
                          did: String,
                          data: AlarmIncidentData
                        )


object AlarmIncident {
  def build(alarmId: Int, macAddress: String, snapshot: Option[TelemetrySnapshot]): AlarmIncident = {
    val timestamp = System.currentTimeMillis

    AlarmIncident(
      randomUUID().toString,
      timestamp,
      macAddress,
      AlarmIncidentData(
        AlarmIncidentAlarmInfo(
          alarmId,
          timestamp
        ),
        Some(snapshot.getOrElse(TelemetrySnapshot.default))
      )
    )
  }
}









