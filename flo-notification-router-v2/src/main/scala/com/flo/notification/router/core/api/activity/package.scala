package com.flo.notification.router.core.api

package object activity {
  type ActivityId = String
  type EntityId   = String

  sealed trait ActivityAction
  case object Created       extends ActivityAction
  case object Updated       extends ActivityAction
  case object Deleted       extends ActivityAction
  case object UnknownAction extends ActivityAction

  sealed trait ActivityType
  case object Device      extends ActivityType
  case object Location    extends ActivityType
  case object Account     extends ActivityType
  case object User        extends ActivityType
  case object UnknownType extends ActivityType

  case class EntityActivity(id: ActivityId, `type`: ActivityType, action: ActivityAction, entityId: EntityId)
}
