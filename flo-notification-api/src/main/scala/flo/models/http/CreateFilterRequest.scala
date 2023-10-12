package flo.models.http

import java.time.LocalDateTime
import com.twitter.finatra.validation.UUID

case class CreateFilterRequest(@UUID id: Option[String],
                               alarmId: Int,
                               `type`: String,
                               @UUID deviceId: Option[String],
                               @UUID locationId: Option[String],
                               @UUID userId: Option[String],
                               @UUID incidentId: Option[String],
                               expiration: LocalDateTime)
