package com.flo.notification.sdk

import com.flo.{FixtureReader, SyncTest}
import com.flo.notification.sdk.circe.DeserializeAlarmIncident

class SerializeAlarmIncidentTest extends SyncTest with FixtureReader {
  "Alarm Incident Serialization" - {

    "should deserialize an alarm incident json" in {
      val deserializeAlarmIncident = new DeserializeAlarmIncident

      val alarmIncident = deserializeAlarmIncident(fixture("com/flo/notification/sdk/alarm-incident.json"))

      alarmIncident.id shouldEqual "f6029a48-4f64-484d-b5e7-18355e00aacc"
    }

  }
}
