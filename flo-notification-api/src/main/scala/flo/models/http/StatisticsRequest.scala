package flo.models.http

import com.twitter.finatra.request.QueryParam
import com.twitter.finatra.validation.UUID

case class StatisticsRequest(
    @QueryParam from: Option[String],
    @QueryParam to: Option[String],
    @QueryParam @UUID locationId: Option[String],
    @QueryParam @UUID deviceId: Option[String],
    @QueryParam @UUID accountId: Option[String],
    @QueryParam @UUID groupId: Option[String]
)

case class StatisticsRequestBatch(locationIds: Option[Set[String]], deviceIds: Option[Set[String]])
