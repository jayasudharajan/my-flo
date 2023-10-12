package flo.models.http

import com.twitter.finatra.request.QueryParam
import com.twitter.finatra.validation.UUID

case class GetAlarmsByFilterRequest(
    @QueryParam isInternal: Option[Boolean],
    @QueryParam enabled: Option[Boolean],
    @QueryParam severity: Option[String],
    @QueryParam lang: Option[String],
    @QueryParam @UUID userId: Option[String],
    @QueryParam accountType: String = "personal"
)
