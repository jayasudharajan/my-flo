package com.flo.notification.sdk.model

import java.text.SimpleDateFormat
import java.util.Date

final case class TelemetrySnapshot(
                            tz: Option[String],
                            lt: Option[String],
                            sm: Option[Int],
                            f: Option[Double],
                            fr: Option[Double],
                            t: Option[Double],
                            p: Option[Double],
                            sw1: Option[Int],
                            sw2: Option[Int],
                            ef: Option[Double],
                            efd: Option[Long],
                            ft: Option[Double],
                            pmin: Option[Double],
                            pmax: Option[Double],
                            tmin: Option[Double],
                            tmax: Option[Double],
                            frl: Option[Double],
                            efl: Option[Double],
                            efdl: Option[Int],
                            ftl: Option[Double],
                            v: Option[Int],
                            humidity: Option[Double] = None,
                            limitHumidityMin: Option[Double] = None,
                            limitHumidityMax: Option[Double] = None,
                            batteryPercent: Option[Int] = None,
                            limitBatteryMin: Option[Int] = None
                          )

object TelemetrySnapshot {
  val default: TelemetrySnapshot = {
    val dateFormat = new SimpleDateFormat("HH:mm:ss")
    val date = new Date

    TelemetrySnapshot(
      Some("Etc/UTC"),
      Some(dateFormat.format(date)),
      Some(2),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(1),
      Some(0),
      Some(-1f),
      Some(-1),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1f),
      Some(-1),
      Some(-1f),
      None
    )
  }
}


