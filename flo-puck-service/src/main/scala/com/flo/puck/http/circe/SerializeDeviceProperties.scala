package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.device.DeviceRequest
import io.circe.syntax._

final private[http] class SerializeDeviceProperties extends (DeviceRequest => String) {

  override def apply(deviceProperties: DeviceRequest): String = {
    import circe._

    deviceProperties.asJson.noSpaces
  }

}