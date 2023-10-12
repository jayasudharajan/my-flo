package com.flo.puck.core.api

sealed trait AlertState
case object AlertInactive    extends AlertState
case object AlertTriggered   extends AlertState
case object AlertResolved    extends AlertState
case object AlertSnoozed     extends AlertState
case object AlertUnknown     extends AlertState