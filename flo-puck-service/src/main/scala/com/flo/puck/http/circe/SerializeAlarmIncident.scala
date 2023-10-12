package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.nrv2.AlarmIncident

import io.circe.syntax._

final private[http] class SerializeAlarmIncident extends (AlarmIncident => String) {

  override def apply(alarmIncident: AlarmIncident): String = {
    import circe._

    alarmIncident.asJson.noSpaces
  }

}