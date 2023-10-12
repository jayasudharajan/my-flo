package flo.models.http

import com.twitter.finatra.request.{QueryParam, RouteParam}
import com.twitter.finatra.validation.UUID

case class FeedbackIdValueRequest(id: String, value: String)

case class UserFeedbackRequest(
    @RouteParam @UUID incidentId: String,
    @QueryParam force: Boolean = false,
    @UUID userId: String,
    options: Seq[FeedbackIdValueRequest]
)
