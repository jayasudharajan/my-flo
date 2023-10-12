package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class DeliverySystemVersionRequest(
    @RouteParam @UUID userId: String
)
