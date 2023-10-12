package com.flo.telemetry.collector.domain

case class TelemetryBatch(
                           did: String,
                           TelemetryBatch: List[SimpleTelemetry]
                         ) {

  def toList(): List[Telemetry] = {
    this.TelemetryBatch.map(x => Telemetry(
      did = this.did,
      t = x.t,
      p = x.p,
      ts = x.ts,
      sm = x.sm,
      fv = x.fv,
      fr = x.fr,
      v = x.v,
      rssi = x.rssi
    ))
  }
}