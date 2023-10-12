package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.nrv2.AlarmEventResponse
import io.circe.parser.decode

final private[http] class DeserializeAlarmEvent extends (String => AlarmEventResponse) {
  override def apply(alarmEventStr: String): AlarmEventResponse = {

    import circe._

    decode[AlarmEventResponse](alarmEventStr) match {
      case Right(event)     => event
      case Left(error)      => throw error
    }
  }
}
