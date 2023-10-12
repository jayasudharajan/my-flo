package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class VoiceCallStatusRequest(@RouteParam @UUID userId: String,
                                  @RouteParam @UUID incidentId: String,
                                  callStatus: String,
                                  data: Map[String, Any])
