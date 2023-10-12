package com.flo.router.telemetry.utils

import java.util.concurrent.TimeUnit
import com.flo.Enums.ValveStatus
import com.flo.router.telemetry.domain.Telemetry
import com.flo.router.telemetry.utils.ConfigUtils.InfluxDBConfig
import com.flo.utils.TimestampCompatibilityHelpers
import org.influxdb.{InfluxDB, InfluxDBFactory}
import org.influxdb.dto.Point
import scala.util.Try
import org.influxdb.BatchOptions
import org.influxdb.InfluxDB.LogLevel

class TelemetryRepository(logLevel: LogLevel, influxDBConfigs: Seq[InfluxDBConfig]) extends ITelemetryRepository {
  val numberOfPointsBeforeFlushPoint = 50000
  val maximumTimeInMsToFlushPoints = 10000
  val influxDBs = influxDBConfigs.map(config => config -> getInfluxDB(config)).toMap

  def getInfluxDB(influxDBConfig: InfluxDBConfig): InfluxDB = {
    val influxDB = InfluxDBFactory.connect(
      s"https://${influxDBConfig.host}:${influxDBConfig.port}",
      influxDBConfig.username,
      influxDBConfig.password
    )

    // Batch Strategy : Flush every {numberOfPointsBeforeFlushPoint} Points, at least every {maximumTimeInMsToFlushPoints} ms
    influxDB.enableBatch(
      BatchOptions
        .DEFAULTS
        .actions(numberOfPointsBeforeFlushPoint)
        .flushDuration(maximumTimeInMsToFlushPoints)
        .bufferLimit(4 * numberOfPointsBeforeFlushPoint)
        .jitterDuration((0.2 * maximumTimeInMsToFlushPoints).toInt)
    )
    influxDB.enableGzip()

    influxDB.setLogLevel(logLevel)

    influxDB
  }

  def save(telemetry: Telemetry): Try[Unit] = {
    Try(
      influxDBConfigs.map(config =>
        save(influxDBs(config), config, telemetry)
      ).head
    ) recover {
      case e: Throwable => throw new Exception(s"${e.toString} :: Trying to save to Influx ::  ${telemetry.toString}")
    }
  }

  private def save(influxDB: InfluxDB, config: InfluxDBConfig, telemetry: Telemetry): Unit = {
    // telemetry comes as a second or millisecond. need to convert to nanoseconds.
    // this is a temporary workaround since telemetry is now in both seconds and milliseconds.
    val nanosecondsTimestamp = TimestampCompatibilityHelpers.toNanosecondsTimestamp(telemetry.ts.get)
    val sw1 = telemetry.sw1.getOrElse(-1)
    val sw2 = telemetry.sw2.getOrElse(-1)
    val v = telemetry.v.getOrElse(ValveStatus.getStatus(sw1, sw2))

    val point = Point.measurement(config.measurement)
      .time(nanosecondsTimestamp, TimeUnit.NANOSECONDS)
      .tag("did", telemetry.did.get)
      .addField("sm", telemetry.sm.getOrElse(0).toLong)
      .addField("v", v.toLong)
      .addField("f", telemetry.f.getOrElse(0D))
      .addField("wf", telemetry.wf.getOrElse(0D))
      .addField("t", telemetry.t.getOrElse(0F))
      .addField("p", telemetry.p.getOrElse(0F))
     // .addField("sw1", sw1)
     // .addField("sw2", sw2)
      .addField("wifi_rssi", telemetry.rssi.getOrElse(0F))
      .build()

    influxDB.write(config.database, config.retentionPolicy, point)
  }
}

trait ITelemetryRepository {
  def save(telemetry: Telemetry):Try[Unit]
}
