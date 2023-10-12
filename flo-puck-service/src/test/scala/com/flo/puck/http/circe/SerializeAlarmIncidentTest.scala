package com.flo.puck.http.circe

import com.flo.SyncTest
import com.flo.puck.http.nrv2.AlarmIncident

class SerializeAlarmIncidentTest extends SyncTest {
  "Alarm Incident serialization" - {
    "should serialize an alarm incident object into a json" in {
      val serializeAlarmIncident = new SerializeAlarmIncident
      val alarmIncident = random[AlarmIncident]
      val alarmIncidentStr = serializeAlarmIncident(alarmIncident)

      alarmIncidentStr should not be empty
    }
  }
}
