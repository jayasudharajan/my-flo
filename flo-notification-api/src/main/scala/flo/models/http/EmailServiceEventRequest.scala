package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class EmailServiceEventRequest(
    @RouteParam @UUID incidentId: String,
    @RouteParam @UUID userId: String,
    receiptId: String
)
