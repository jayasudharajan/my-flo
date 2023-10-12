package com.flo.notification.router.core.api.alert

sealed trait AlertStatus
case object Resolved   extends AlertStatus
case object Ignored    extends AlertStatus
case object Unresolved extends AlertStatus
case object Muted      extends AlertStatus
