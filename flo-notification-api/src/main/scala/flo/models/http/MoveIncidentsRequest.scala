package flo.models.http

import com.twitter.finatra.validation.UUID

case class MoveIncidentsRequest(@UUID srcAccountId: String,
                                @UUID destAccountId: String,
                                @UUID srcLocationId: String,
                                @UUID destLocationId: String,
                                @UUID deviceId: String)
