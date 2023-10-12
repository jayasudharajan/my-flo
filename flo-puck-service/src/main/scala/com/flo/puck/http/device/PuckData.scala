package com.flo.puck.http.device

import com.flo.puck.core.api.{AudioSettings, PuckTelemetry}

case class PuckData(telemetry: Option[PuckTelemetry],
                    audioSettings: Option[AudioSettings])
