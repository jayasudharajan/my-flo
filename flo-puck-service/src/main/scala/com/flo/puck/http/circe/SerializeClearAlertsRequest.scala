package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.nrv2.ClearAlertsRequest

import io.circe.syntax._

final private[http] class SerializeClearAlertsRequest extends (ClearAlertsRequest => String) {

  override def apply(clearAlertsRequest: ClearAlertsRequest): String = {
    import circe._

    clearAlertsRequest.asJson.noSpaces
  }

}