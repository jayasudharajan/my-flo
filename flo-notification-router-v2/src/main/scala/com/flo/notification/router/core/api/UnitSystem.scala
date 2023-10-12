package com.flo.notification.router.core.api

sealed trait UnitSystem

case object Imperial extends UnitSystem
case object Metric   extends UnitSystem

object UnitSystem {
  val values: Set[UnitSystem] = ca.mrvisser.sealerate.values[UnitSystem]
}
