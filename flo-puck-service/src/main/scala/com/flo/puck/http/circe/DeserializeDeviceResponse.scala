package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.gateway.DeviceResponse
import io.circe.parser.decode

final private[http] class DeserializeDeviceResponse extends (String => DeviceResponse) {
  override def apply(deviceResponseStr: String): DeviceResponse = {

    import circe._

    decode[DeviceResponse](deviceResponseStr) match {
      case Right(deviceResponse)  => deviceResponse
      case Left(error)            => throw error
    }
  }
}
