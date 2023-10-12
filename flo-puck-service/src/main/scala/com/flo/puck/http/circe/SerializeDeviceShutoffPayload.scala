package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.gateway.DeviceShutoffPayload
import io.circe.syntax._

final private[http] class SerializeDeviceShutoffPayload extends (DeviceShutoffPayload => String) {

  override def apply(devicePayload: DeviceShutoffPayload): String = {
    import circe._

    devicePayload.asJson.noSpaces
  }

}