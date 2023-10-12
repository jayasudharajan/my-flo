package com.flo.puck.kafka.circe

import com.flo.puck.kafka.circe
import com.flo.puck.kafka.nrv2.AlarmNotificationStatus
import io.circe.syntax._

final private[kafka] class SerializeAlarmNotificationStatus extends (AlarmNotificationStatus => String) {

  override def apply(alarmNotificationStatus: AlarmNotificationStatus): String = {
    import circe._

    alarmNotificationStatus.asJson.noSpaces
  }

}