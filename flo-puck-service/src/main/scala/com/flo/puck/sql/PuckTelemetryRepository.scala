package com.flo.puck.sql

import java.sql.PreparedStatement
import java.time.{LocalDateTime, ZoneId}
import java.time.temporal.{ChronoUnit, TemporalUnit}

import com.flo.logging.logbookFor
import com.flo.puck.core.api._
import javax.sql.DataSource
import perfolation._

import scala.concurrent.{ExecutionContext, Future, blocking}
import scala.util.Try
import scala.util.control.NonFatal

class PuckTelemetryRepository(dataSource: DataSource)(implicit ec: ExecutionContext) {

  import PuckTelemetryRepository.log

  private val InsertPuckTelemetry =
    """INSERT INTO puck_telemetry
      |(mac_address, device_id, battery_voltage, battery_percentage, humidity, temperature, telemetry)
      |VALUES (?, ?, ?, ?, ?, ?, ?::json)""".stripMargin.replaceAll("\n", " ")

  private val dateExpressionRegex = "DATE_EXPR".r
  private val whereClauseRegex = "WHERE_CLAUSE".r
  private val RetrievePuckTelemetry =
    """SELECT DATE_EXPR AS date,
      |  ROUND(AVG(battery_voltage)::numeric, 3) AS avgBatteryVoltage,
      |  ROUND(AVG(battery_percentage)::numeric, 3) AS avgBatteryPercentage,
      |  ROUND(AVG(humidity)::numeric, 3) AS avgHumidity,
      |  ROUND(AVG(temperature)::numeric, 3) AS avgTemperature
      |FROM puck_telemetry
      |WHERE WHERE_CLAUSE
      |GROUP BY date
      |ORDER BY date
      |""".stripMargin.replaceAll("\n", " ")

  def appendPuckTelemetry(puckTelemetry: PuckTelemetry): Future[Unit] = {
    withConnection[Unit](InsertPuckTelemetry, { statement =>
      statement.setString(1, puckTelemetry.properties.macAddress)
      statement.setString(2, puckTelemetry.properties.deviceId.getOrElse(""))
      statement.setDouble(3, puckTelemetry.properties.telemetryBatteryVoltage.getOrElse(0))
      statement.setInt(4, puckTelemetry.properties.telemetryBatteryPercent.getOrElse(0))
      statement.setDouble(5, puckTelemetry.properties.telemetryHumidity.getOrElse(0))
      statement.setDouble(6, puckTelemetry.properties.telemetryTemperature.getOrElse(0))
      statement.setString(7, puckTelemetry.raw.noSpaces)
      statement.execute()
    })
  }

  def retrievePuckTelemetry(macAddress: String, interval: Interval, timeZone: TimeZone, maybeStartDate: Option[StartDate], maybeEndDate: Option[EndDate]): Future[PuckTelemetryReport] = {
    val truncatedDateExpr = p"date_trunc('${toSql(interval)}', created_time AT TIME ZONE 'UTC' AT TIME ZONE '$timeZone')"

    val whereConditions: Seq[String] = Seq(
      Some("mac_address = ?"),
      Some("created_time >= ?"),
      Some("created_time < ?"),
    ).flatten

    val whereClause = whereConditions.mkString(" AND ")

    val query = whereClauseRegex.replaceFirstIn(
      dateExpressionRegex.replaceFirstIn(RetrievePuckTelemetry, truncatedDateExpr),
      whereClause)

    withConnection[PuckTelemetryReport](query, { statement =>
      var paramIndex = 1
      statement.setString(paramIndex, macAddress)
      maybeStartDate.foreach { startDate =>
        paramIndex += 1
        val truncatedStartDate = startDate.truncatedTo(toTemporalUnit(interval))
        statement.setObject(paramIndex, toUtc(truncatedStartDate, timeZone))
      }
      maybeEndDate.foreach { endDate =>
        paramIndex += 1
        val truncatedEndDate = endDate.truncatedTo(toTemporalUnit(interval))
        statement.setObject(paramIndex, toUtc(truncatedEndDate, timeZone))
      }

      val rs = statement.executeQuery()
      val puckTelemetryItems = Iterator
        .continually(rs)
        .takeWhile(_.next())
        .map { _ =>
          PuckTelemetryItem(
            date = rs.getObject("date", classOf[LocalDateTime]),
            avgBatteryVoltage = rs.getDouble("avgBatteryVoltage"),
            avgBatteryPercentage = rs.getDouble("avgBatteryPercentage"),
            avgHumidity = rs.getDouble("avgHumidity"),
            avgTemperature = rs.getDouble("avgTemperature")
          )
        }.toList

      PuckTelemetryReport(items = puckTelemetryItems)
    })
  }

  private def toSql(interval: Interval): String = interval match {
    case Hourly => "hour"
    case Daily => "day"
    case Monthly => "month"
  }

  private def toUtc(date: LocalDateTime, timeZone: TimeZone): LocalDateTime = {
    date.atZone(timeZone).withZoneSameInstant(ZoneId.of("UTC")).toLocalDateTime
  }

  private def toTemporalUnit(interval: Interval): TemporalUnit = interval match {
    case Hourly => ChronoUnit.HOURS
    case Daily => ChronoUnit.DAYS
    case Monthly => ChronoUnit.MONTHS
  }

  private def withConnection[A](query: String, withStatement: PreparedStatement => A): Future[A] = {
    Future {
      blocking {
        val maybeConnection = Try(dataSource.getConnection)
        val maybeStatement = maybeConnection.map(_.prepareStatement(query))
        val maybeExecution = maybeStatement.map { statement =>
          withStatement(statement)
        }

        try {
          maybeExecution.get
        } finally {
          close(maybeStatement)
          close(maybeConnection)
        }
      }
    }
  }

  private def close(maybeAutoCloseable: Try[AutoCloseable]): Unit = {
    maybeAutoCloseable.foreach { autoCloseable =>
      try {
        autoCloseable.close()
      } catch {
        case NonFatal(e) => log.warn(p"Error closing resource: $e")
      }
    }
  }

}

object PuckTelemetryRepository {
  private val log = logbookFor(getClass)
}


