package com.flo.puck.kafka.circe

import java.time.LocalDateTime

import com.flo.puck.core.api.activity.{Alert, Deleted, Snoozed, DiscardedType, Updated}
import com.flo.{FixtureReader, SyncTest}

class DeserializeEntityActivityTest extends SyncTest with FixtureReader {
  "Entity Activity Deserialization" - {

    "should deserialize entity activity" in {
      val entityActivityDeserializer = new DeserializeEntityActivity

      val entityActivity = entityActivityDeserializer(fixture("com/flo/puck/kafka/circe/entity-activity.json"))

      entityActivity.`type` shouldEqual Alert
      entityActivity.action shouldEqual Updated
      entityActivity.item.get.device.macAddress shouldEqual "d8a01d6717e4"
      entityActivity.item.get.reason.get shouldEqual Snoozed
      entityActivity.item.get.snoozeTo.get shouldEqual LocalDateTime.of(2020, 1, 3, 19, 40, 8)
    }

    "should deserialize to none an item that is not recognized" in {
      val entityActivityDeserializer = new DeserializeEntityActivity

      val entityActivity = entityActivityDeserializer(fixture("com/flo/puck/kafka/circe/entity-activity-with-unrecognized-item.json"))

      entityActivity.`type` shouldEqual DiscardedType
      entityActivity.action shouldEqual Deleted
      entityActivity.item shouldBe None
    }
  }
}
