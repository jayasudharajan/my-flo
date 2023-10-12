package com.flo.puck.http.nrv2

import com.flo.SyncTest
import com.flo.puck.core.api.{Device, PuckTelemetry}
import com.softwaremill.quicklens._

class TelemetryIncidentAdapterTest extends SyncTest {
  "Puck Telemetry Incident Adapter" - {
    "should convert puck telemetry into an alarm incident" in {
      def generateUuid: String = java.util.UUID.randomUUID().toString

      val puckTelemetry = random[PuckTelemetry].modify(_.properties.macAddress).setTo("606405c074ba")
      val incidentAdapterFactory: AlarmId => TelemetryIncidentAdapter = alarmId =>
        new TelemetryIncidentAdapter(alarmId, generateUuid)
      val alarmId = 1001
      val device = random[Device]
      val alarmIncident: AlarmIncident = incidentAdapterFactory(alarmId)(puckTelemetry.properties, device)

      alarmIncident.macAddress shouldBe puckTelemetry.properties.macAddress
      alarmIncident.alarmId shouldBe alarmId
    }
  }
}
