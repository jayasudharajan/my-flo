package com.flo.notification.sdk.model

object AlarmHelper {
  private val smallDripAlerts = Set(28, 29, 30, 31)
  private val shutoffAlarms: Set[Int] = Set(51, 52, 53, 55, 80, 89)
  private val triggers: Map[Int, Int] = Map(
    10 -> 51,
    11 -> 52,
    26 -> 53,
    70 -> 80,
    71 -> 81,
    72 -> 82,
    73 -> 83,
    74 -> 84,
    75 -> 85,
    76 -> 86,
    77 -> 87,
    78 -> 88,
    79 -> 89
  )

  private val alarmMap = triggers.map(x => (x._2, x._1))

  def getAssociatedAlarmIds(alarmId: Int): List[Int] = {
    alarmMap.get(alarmId) match {
      case Some(associatedAlarmId) =>
        List(associatedAlarmId)

      case None =>
        if (smallDripAlerts.contains(alarmId)) {
          smallDripAlerts.filterNot(_ == alarmId).toList
        } else {
          Nil
        }
    }
  }

  def getIsShutoff(alarmId: Int): Boolean =
    shutoffAlarms.contains(alarmId)
}
