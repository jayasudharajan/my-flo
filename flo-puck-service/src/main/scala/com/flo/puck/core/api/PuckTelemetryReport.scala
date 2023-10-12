package com.flo.puck.core.api

import java.time.LocalDateTime

case class PuckTelemetryItem(date: LocalDateTime, avgBatteryVoltage: Double, avgBatteryPercentage: Double, avgHumidity: Double, avgTemperature: Double)

case class PuckTelemetryReport(items: Seq[PuckTelemetryItem])
