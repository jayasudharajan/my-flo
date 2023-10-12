package com.flo.telemetry.collector.domain

case class SimpleTelemetry(
                            fr: Option[Double],
                            fv: Option[Double],
                            t: Option[Float],
                            p: Option[Float],
                            ts: Option[Long],
                            sm: Option[Int],
                            v: Option[Int],
                            rssi: Option[Float]
                          )
