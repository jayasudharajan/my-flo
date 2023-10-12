package com.flo.router.telemetry.domain

case class Telemetry(
                      wf: Option[Double] = None,
                      t: Option[Float] = None,
                      p: Option[Float] = None,
                      sw1: Option[Int] = None,
                      sw2: Option[Int] = None,
                      did: Option[String] = None,
                      ts: Option[Long] = None,
                      sm: Option[Int] = None,
                      f: Option[Double] = None,
                      v: Option[Int] = None,
                      rssi: Option[Float] = None
                    )