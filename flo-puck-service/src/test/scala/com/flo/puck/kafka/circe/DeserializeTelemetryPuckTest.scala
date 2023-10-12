package com.flo.puck.kafka.circe

import com.flo.{FixtureReader, SyncTest}
import com.flo.puck.core.api.{AlertTriggered}

class DeserializeTelemetryPuckTest extends SyncTest with FixtureReader {
  "Puck Telemetry Deserialization" - {
    "should deserialize a puck telemetry json" in {
      val puckTelemetryDeserializer = new DeserializeTelemetryPuck

      val puckTelemetry = puckTelemetryDeserializer(fixture("com/flo/puck/kafka/circe/puck-telemetry.json"))

      puckTelemetry.properties.macAddress shouldBe "606405c074ba"
      puckTelemetry.properties.deviceId.get shouldBe "b38a1f53-73e2-420a-914c-5ecea76f6d9f"
      puckTelemetry.properties.alertState.get shouldBe AlertTriggered

      puckTelemetry.raw.hcursor.downField("device_id").as[String].right.get shouldBe "606405c074ba"
      puckTelemetry.raw.hcursor.downField("device_uuid").as[String].right.get shouldBe "b38a1f53-73e2-420a-914c-5ecea76f6d9f"
    }
  }
}
