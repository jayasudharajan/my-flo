package com.flo.push.kafka

import com.flo.push.kafka.circe.DeserializePushNotification
import com.flo.{FixtureReader, SyncTest}

class DeserializePushNotificationTest extends SyncTest with FixtureReader {
  "Deserialize Push Notification" - {
    "should deserialize a push notification correctly" in {
      val deserializePushNotification = new DeserializePushNotification

      val pn = deserializePushNotification(fixture("com/flo/push/kafka/push-notification.json"))

      pn.requestId shouldEqual "f6029a48-4f64-484d-b5e7-18355e00aac4"
      pn.userId shouldEqual "03112551-2633-473a-8d77-996d93c21dfb"
      pn.deviceId shouldEqual "03112551-2633-473a-8d77-996d93c21dfc"
      pn.title shouldEqual "Push Title"
      pn.body shouldEqual "Push Body"
      pn.tag shouldEqual "113"
      pn.color shouldEqual "#D7342F"
      pn.clickAction shouldEqual "com.flotechnologies.intent.action.INCIDENT"
      pn.metadata.noSpaces shouldNot be(empty)
    }
  }
}
