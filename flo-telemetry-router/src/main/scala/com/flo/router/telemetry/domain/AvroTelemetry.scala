package com.flo.router.telemetry.domain

import com.sksamuel.avro4s.{AvroName, AvroNamespace}

@AvroName("KsqlDataSourceSchema")
@AvroNamespace("io.confluent.ksql.avro_schemas")
case class AvroTelemetry(
                          @AvroName("FR") fr: Option[Double] = None,
                          @AvroName("FV") fv: Option[Double] = None,
                          @AvroName("T") t: Option[Double] = None,
                          @AvroName("P") p: Option[Double] = None,
                          @AvroName("SW1") sw1: Option[Int] = None,
                          @AvroName("SW2") sw2: Option[Int] = None,
                          @AvroName("DID") did: Option[String] = None,
                          @AvroName("TS") ts: Option[Long] = None,
                          @AvroName("SM") sm: Option[Int] = None,
                          @AvroName("V") v: Option[Int] = None,
                          @AvroName("RSSI") rssi: Option[Double] = None
                        ) {

  def toTelemetry(): Telemetry = Telemetry(
    fr,
    t.map(x => x.toFloat),
    p.map(x => x.toFloat),
    sw1,
    sw2,
    did,
    ts,
    sm,
    fv.map(x => x.toFloat),
    v,
    rssi.map(x => x.toFloat)
  )
}