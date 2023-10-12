package com.flo.notification.router.core.api

sealed trait AlarmStatus
case object Received                                     extends AlarmStatus
case class Filtered(reason: FilterReason)                extends AlarmStatus
case object Triggered                                    extends AlarmStatus
case class Resolved(reason: Option[FilterReason] = None) extends AlarmStatus
