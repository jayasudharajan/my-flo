package com.flo.puck.core.report

import com.flo.puck.core.api._
import com.flo.puck.core.report.conf.PuckTelemetryReportConfig

import scala.concurrent.Future

class BuildPuckTelemetryReport(puckTelemetryReportConfig: PuckTelemetryReportConfig,
                               retrievePuckTelemetryReport: PuckTelemetryReportRetriever) extends PuckTelemetryReportBuilder {

  override def apply(macAddress: MacAddress, maybeInterval: Option[Interval], maybeTimeZone: Option[TimeZone],
                     maybeStartDate: Option[StartDate], maybeEndDate: Option[EndDate]): Future[PuckTelemetryReport] = {

    val interval = maybeInterval.getOrElse(puckTelemetryReportConfig.defaultInterval)
    val timeZone = maybeTimeZone.getOrElse(puckTelemetryReportConfig.defaultTimeZone)

    retrievePuckTelemetryReport(macAddress, interval, timeZone, maybeStartDate, maybeEndDate)
  }
}
