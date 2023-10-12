package com.flo.scheduler

import java.time.{LocalDateTime, ZoneOffset}

import io.circe._
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.deriveConfiguredEncoder

package object circe {
  implicit val customConfig: Configuration = Configuration.default.withDefaults

  implicit val localDateTimeEncoder: Encoder[LocalDateTime] =
    Encoder.encodeString.contramap[LocalDateTime](_.withNano(0).toInstant(ZoneOffset.UTC).toString)

  implicit val fixedDateScheduleConfigEncoder: Encoder[FixedDateScheduleConfig] = deriveConfiguredEncoder

  implicit val fixedDateScheduleEncoder: Encoder[FixedDateSchedule] = deriveConfiguredEncoder

  implicit val kafkaTransportPayloadEncoder: Encoder[KafkaTransportPayload] = deriveConfiguredEncoder
  implicit val httpTransportPayloadEncoder: Encoder[HttpTransportPayload]   = deriveConfiguredEncoder

  implicit val kafkaTransportEncoder: Encoder[KafkaTransport] = deriveConfiguredEncoder
  implicit val httpTransportEncoder: Encoder[HttpTransport]   = deriveConfiguredEncoder

  implicit val kafkaTaskEncoder: Encoder[KafkaTask] = deriveConfiguredEncoder
  implicit val httpTaskEncoder: Encoder[HttpTask]   = deriveConfiguredEncoder
}
