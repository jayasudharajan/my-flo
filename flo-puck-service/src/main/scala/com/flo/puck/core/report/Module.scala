package com.flo.puck.core.report

import com.flo.puck.conf._
import com.flo.puck.core.api.{Interval, PuckTelemetryReportBuilder, PuckTelemetryReportRetriever}
import com.flo.puck.core.report.conf.PuckTelemetryReportConfig
import com.typesafe.config.Config
import pureconfig.ConfigReader
import pureconfig.generic.semiauto._

trait Module {
  // Requires
  def appConfig: Config
  def retrievePuckTelemetryReport: PuckTelemetryReportRetriever

  // Private
  private implicit val intervalReader: ConfigReader[Interval] = deriveEnumerationReader[Interval]
  private val puckTelemetryReportConfig = appConfig.as[PuckTelemetryReportConfig]("puck-telemetry-report")

  // Provides
  val buildPuckTelemetryReport: PuckTelemetryReportBuilder = new BuildPuckTelemetryReport(puckTelemetryReportConfig, retrievePuckTelemetryReport)

}
