package flo.models.http

import com.twitter.finatra.validation.UUID

case class RandomEventsRequest(
    @UUID userId: String,
    @UUID deviceId: String
)
