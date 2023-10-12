package flo.models.http

import com.twitter.finatra.request.{QueryParam, RouteParam}
import com.twitter.finatra.validation.UUID

case class ByIntIdRequest(
    @RouteParam id: Int,
    @QueryParam lang: Option[String],
    @QueryParam @UUID userId: Option[String],
    @QueryParam accountType: String = "personal"
)

case class ByUUIDIdRequest(
    @RouteParam @UUID id: String,
    @QueryParam lang: Option[String],
    @QueryParam unitSystem: Option[String]
)
