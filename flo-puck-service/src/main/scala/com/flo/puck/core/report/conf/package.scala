package com.flo.puck.core.report

import com.flo.puck.core.api.{Interval, TimeZone}

package object conf {
  private[report] case class PuckTelemetryReportConfig(defaultInterval: Interval, defaultTimeZone: TimeZone)
}
