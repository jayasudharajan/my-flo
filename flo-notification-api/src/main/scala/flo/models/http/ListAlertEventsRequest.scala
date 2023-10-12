package flo.models.http

import com.twitter.finatra.request.QueryParam
import com.twitter.finatra.validation.UUID

case class ListAlertEventsRequest(
    @QueryParam locationId: Seq[String] = Nil,
    @QueryParam deviceId: Seq[String] = Nil,
    @QueryParam @UUID accountId: Option[String],
    @QueryParam @UUID groupId: Option[String],
    @QueryParam createdAt: Seq[String] = Nil,
    @QueryParam severity: Seq[String] = Nil,
    @QueryParam status: Seq[String] = Nil,
    @QueryParam reason: Seq[String] = Nil,
    @QueryParam isInternalAlarm: Option[Boolean],
    @QueryParam lang: Option[String],
    @QueryParam unitSystem: Option[String],
    @QueryParam page: Option[Int],
    @QueryParam size: Option[Int]
)
