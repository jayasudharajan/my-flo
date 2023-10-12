package com.flo.notification.sdk

import com.flo.notification.sdk.circe.DeserializeAlert
import com.flo.{FixtureReader, SyncTest}

class SerializeAlert extends SyncTest with FixtureReader {
  "Alert Serialization" - {
    "should deserialize Alert" in {
      val deserializeAlert = new DeserializeAlert

      val alert = deserializeAlert(fixture("com/flo/notification/sdk/alert.json"))

      alert.alarmId shouldEqual 15
    }
  }
}
