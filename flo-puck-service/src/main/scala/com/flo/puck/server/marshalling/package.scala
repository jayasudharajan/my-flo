package com.flo.puck.server

import java.time.format.DateTimeFormatter
import java.time.{LocalDateTime, ZoneId}

import akka.http.scaladsl.unmarshalling.Unmarshaller
import com.flo.puck.core.api.{Daily, Hourly, Interval, Monthly, PuckTelemetryItem, PuckTelemetryReport, TimeZone}
import de.heikoseeberger.akkahttpcirce.{BaseCirceSupport, FailFastCirceSupport}
import io.circe.Encoder
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.deriveConfiguredEncoder

package object marshalling {
  implicit val intervalUnmarshaller: Unmarshaller[String, Interval] = Unmarshaller.strict[String, Interval] {
    case "1h" => Hourly
    case "1d" => Daily
    case "1m" => Monthly
  }

  implicit val timeZoneUnmarshaller: Unmarshaller[String, TimeZone] = Unmarshaller.strict[String, TimeZone](ZoneId.of)

  implicit val localDateTimeUnmarshaller: Unmarshaller[String, LocalDateTime] =
    Unmarshaller.strict[String, LocalDateTime](LocalDateTime.parse)

  implicit val customConfig: Configuration = Configuration.default.withDefaults
  implicit val localDateTimeEncoder: Encoder[LocalDateTime] =
    Encoder.encodeString.contramap[LocalDateTime](DateTimeFormatter.ISO_LOCAL_DATE_TIME.format)
  implicit val puckTelemetryItemEncoder: Encoder[PuckTelemetryItem] = deriveConfiguredEncoder
  implicit val puckTelemetryReportEncoder: Encoder[PuckTelemetryReport] = deriveConfiguredEncoder

  implicit val jsonSupport: BaseCirceSupport = FailFastCirceSupport
}
