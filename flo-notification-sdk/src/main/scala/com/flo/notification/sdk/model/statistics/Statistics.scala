package com.flo.notification.sdk.model.statistics

case class DeviceStat(count: Long, absolute: Long)

case class Stat(count: Long, devices: DeviceStat)

object Stat {
  def empty = Stat(0, DeviceStat(0, 0))
}

case class Statistics(
  info: Stat,
  warning: Stat,
  critical: Stat,
  alarmCount: Map[Int, Long]
)
