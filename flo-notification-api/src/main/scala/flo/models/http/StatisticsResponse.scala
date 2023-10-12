package flo.models.http

import com.flo.notification.sdk.model.statistics.{DeviceStat, Stat, Statistics}

case class PendingCounts(infoCount: Long,
                         warningCount: Long,
                         criticalCount: Long,
                         alarmCount: Seq[AlarmStats],
                         info: Stat,
                         warning: Stat,
                         critical: Stat)

case class StatisticsResponse(pending: PendingCounts)

case class AlarmStats(id: Int, severity: Option[String], count: Long)

object StatisticsResponse {
  val example = StatisticsResponse(
    PendingCounts(
      34,
      42,
      5,
      Seq(
        AlarmStats(1, Some("info"), 34),
        AlarmStats(2, Some("warning"), 20),
        AlarmStats(3, Some("warning"), 22),
        AlarmStats(4, Some("critical"), 5)
      ),
      info = Stat(34, DeviceStat(34, 0)),
      warning = Stat(42, DeviceStat(42, 41)),
      critical = Stat(5, DeviceStat(5, 5))
    )
  )

  def apply(stats: Statistics, alarms: Map[Int, AlarmResponse]): StatisticsResponse = {
    val alarmCount = stats.alarmCount.map {
      case (alarmId, count) =>
        AlarmStats(alarmId, alarms.get(alarmId).map(_.severity), count)
    }.toSeq
    StatisticsResponse(
      PendingCounts(
        infoCount = stats.info.count,
        warningCount = stats.warning.count,
        criticalCount = stats.critical.count,
        alarmCount = alarmCount,
        info = stats.info,
        warning = stats.warning,
        critical = stats.critical
      )
    )
  }
}

case class StatisticsResponseBatch(locationIds: Map[String, StatisticsResponse],
                                   deviceIds: Map[String, StatisticsResponse])
