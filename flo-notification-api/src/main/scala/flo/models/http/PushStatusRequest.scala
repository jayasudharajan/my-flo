package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class PushStatusRequest(@RouteParam @UUID userId: String, @RouteParam @UUID incidentId: String, status: String)
