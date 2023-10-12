package com.flo.notification.sdk.model.statistics

import java.time.LocalDateTime
import java.util.UUID

case class Filter(
  from: Option[LocalDateTime] = None,
  to: Option[LocalDateTime] = None,
  accountId: Option[UUID] = None,
  locationId: Option[UUID] = None,
  icdId: Option[UUID] = None,
  groupId: Option[UUID] = None
)

case class BatchStatisticsFilter(locationIds: Option[Set[UUID]],
                                 deviceIds: Option[Set[UUID]])