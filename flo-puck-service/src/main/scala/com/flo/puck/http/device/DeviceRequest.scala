package com.flo.puck.http.device

import com.flo.puck.core.api.AudioSettings
import io.circe.Json

case class DeviceRequest(
                          fwProperties: Option[Json],
                          fwVersion: Option[String],
                          audio: Option[AudioSettings]
)
