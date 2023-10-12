package com.flo.notification.sdk.circe

import com.flo.notification.router.core.api.AlarmIncident
import com.flo.notification.sdk.circe
import io.circe.parser.decode
import io.circe.syntax._

final private[sdk] class SerializeAlarmIncident extends (AlarmIncident => String) {

  override def apply(alarmIncident: AlarmIncident): String = {
    import circe._
    alarmIncident.asJson.noSpaces
  }

}

final private[sdk] class DeserializeAlarmIncident extends (String => AlarmIncident) {

  override def apply(alarmIncidentStr: String): AlarmIncident = {
    import circe._

    decode[AlarmIncident](alarmIncidentStr) match {
      case Right(kafkaAlarmIncident) => kafkaAlarmIncident
      case Left(error)               => throw error
    }
  }

}
