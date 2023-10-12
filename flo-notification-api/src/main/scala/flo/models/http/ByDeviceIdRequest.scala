package flo.models.http

import com.twitter.finatra.request.QueryParam
import com.twitter.finatra.validation.UUID

case class ByDeviceIdRequest(@QueryParam @UUID deviceId: String)
