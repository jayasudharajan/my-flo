package flo.models.http

import com.twitter.finatra.validation.UUID

case class EventSearchRequest(
    @UUID accountId: Option[String],
    @UUID groupId: Option[String],
    locationId: Set[String] = Set(),
    deviceId: Set[String] = Set(),
    status: Set[String] = Set(),
    severity: Set[String] = Set(),
    alarmId: Set[Int] = Set(),
    reason: Set[String] = Set(),
    createdAt: Set[String] = Set(),
    isInternalAlarm: Option[Boolean],
    lang: Option[String],
    unitSystem: Option[String],
    page: Option[Int],
    size: Option[Int]
)
