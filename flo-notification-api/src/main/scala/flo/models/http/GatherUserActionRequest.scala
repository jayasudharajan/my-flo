package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class GatherUserActionRequest(@RouteParam @UUID userId: String,
                                   @RouteParam @UUID incidentId: String,
                                   gatherUrl: String,
                                   callSid: String,
                                   digits: String,
                                   rawData: Map[String, Any])
