package com.flo.telemetry.collector.domain

case class Telemetry(
                      t: Option[Float],
                      p: Option[Float],
                      did: String,
                      ts: Option[Long],
                      sm: Option[Int],
                      fv: Option[Double],
                      fr: Option[Double],
                      v: Option[Int],
                      rssi: Option[Float]
                    ) {

  def toSimple(): SimpleTelemetry = SimpleTelemetry(
    t = this.t,
    p = this.p,
    ts = this.ts,
    sm = this.sm,
    fv = this.fv,
    fr = this.fr,
    v = this.v,
    rssi = this.rssi
  )
}

/*
case class Telemetry(
                      t: Float,
                      p: Float,
                      did: String,
                      ts: Long,
                      sm: Int,
                      fv: Double,
                      fr: Double,
                      v: Int,
                      rssi: Float
                    )

import org.apache.avro.Schema

  val schema2 = new Schema.Parser().parse(
  """
  {
    "type":"record",
    "name":"Telemetry",
    "namespace":"com.flotechnologies",
    "fields":[
    {"name": "did", "type": "string"},
    {"name": "ts", "type": "long"},
    {"name": "fr", "type": "double"},
    {"name": "fv", "type": "double" },
    {"name": "p", "type": "float" },
    {"name": "t", "type": "float"},
    {"name": "v", "type": "int"},
    {"name": "rssi", "type": "float"},
    {"name": "sm", "type": "int"}
    ]
  }"""
  )
 */