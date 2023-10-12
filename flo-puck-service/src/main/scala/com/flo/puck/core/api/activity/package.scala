package com.flo.puck.core.api

import java.time.LocalDateTime

package object activity {
  type ActivityId = String

  sealed trait ActivityAction
  case object Created                 extends ActivityAction
  case object Updated                 extends ActivityAction
  case object Deleted                 extends ActivityAction
  case object DiscardedActivityAction extends ActivityAction

  sealed trait ActivityType
  case object Alert         extends ActivityType
  case object DiscardedType extends ActivityType

  sealed trait ActivityStatus
  case object Received        extends ActivityStatus
  case object Filtered        extends ActivityStatus
  case object Triggered       extends ActivityStatus
  case object Resolved        extends ActivityStatus
  case object DiscardedStatus extends ActivityStatus

  sealed trait ActivityReason
  case object Snoozed         extends ActivityReason
  case object DiscardedReason extends ActivityReason

  case class EntityActivityDevice(id: String, macAddress: String)

  case class EntityActivityItem(device: EntityActivityDevice,
                                status: ActivityStatus,
                                reason: Option[ActivityReason],
                                snoozeTo: Option[LocalDateTime])

  case class EntityActivity(id: ActivityId, `type`: ActivityType, action: ActivityAction, item: Option[EntityActivityItem])
}
