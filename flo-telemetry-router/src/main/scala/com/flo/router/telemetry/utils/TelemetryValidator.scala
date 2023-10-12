package com.flo.router.telemetry.utils

import java.util.Date
import com.flo.router.telemetry.domain.Telemetry
import org.joda.time.{DateTime, DateTimeZone}

object TelemetryValidator {
  def shouldBeDropped(telemetry: Telemetry): Boolean = {
    val threshold = ConfigUtils.telemetry.filters.timestampThresholdInDays
    val telemetryTsDate = new DateTime(new Date(telemetry.ts.getOrElse(0L))).toDateTime(DateTimeZone.UTC)
    val isAfterLimit = telemetryTsDate.isAfter(
      DateTime.now(DateTimeZone.UTC).plusDays(threshold)
    )
    val isBeforeLimit = telemetryTsDate.isBefore(
      DateTime.now(DateTimeZone.UTC).minusDays(threshold)
    )

    isBeforeLimit || isAfterLimit
  }

  def isValid(telemetry: Telemetry): Boolean = {
    val fValidation = telemetry.f.map(x => x >= 0 && x <= 2).getOrElse(true)
    val pValidation = telemetry.p.map(x => x >= 0 && x <= 200).getOrElse(true)
    val tValidation = telemetry.t.map(x => x >= 0 && x <= 200).getOrElse(true)
    val wfValidation = telemetry.wf.map(x => x >= 0 && x <= 120).getOrElse(true)
    val smValidation = telemetry.sm.map(x => x >= 1 && x <= 5).getOrElse(true)
    val sw1Validation = telemetry.sw1.map(x => x == 0 || x == 1).getOrElse(true)
    val sw2Validation = telemetry.sw2.map(x => x == 0 || x == 1).getOrElse(true)

    fValidation && pValidation && tValidation && wfValidation &&
    smValidation && sw1Validation && sw2Validation
  }
}
