package MicroService

import com.flo.Enums.Notifications.AlarmNotificationStatuses
import com.flo.Models.{AlarmNotificationDeliveryFilters, ICDAlarmNotificationFilterSettings}
import com.typesafe.scalalogging.LazyLogging
import org.joda.time.{DateTime, DateTimeZone}


class FrequencyService extends LazyLogging {
  private lazy val timeService = new TimeService()


  /**
    * frequencyIsAlright has to do with the frequency interval we want a user to get notified about an icdAlarmIncident
    **/
  ///TODO: Metric timer
  def isFrequencyAlright(alarmFilter: Option[AlarmNotificationDeliveryFilters], filterSettings: ICDAlarmNotificationFilterSettings, isScheduled: Boolean = false, isSleepModeCS: Boolean = false): Boolean = {
    var frequencyIsAlright = true
    if ((alarmFilter.get.icdId.nonEmpty && !alarmFilter.get.status.get.equals(AlarmNotificationStatuses.RESOLVED) && alarmFilter.get.icdId.isDefined && !filterSettings.exempted) || isSleepModeCS) {
      ////STATUS
      val currentTime = DateTime.now(DateTimeZone.UTC)
      val lastStatusUpdate = new DateTime(alarmFilter.get.updatedAt.get)
      val millisElapsedSinceLastUpdate = currentTime.getMillis - lastStatusUpdate.getMillis
      frequencyIsAlright = if (millisElapsedSinceLastUpdate >
        timeService.deliveryIntervalsInMilliSecondsGenerator(filterSettings.maxDeliveryAmountScope, filterSettings.maxDeliveryAmount)) true else false
      if (!frequencyIsAlright && isScheduled) {
        frequencyIsAlright = true
        logger.info(s"Frequency overwritten for scheduled notification icd id:${alarmFilter.get.icdId.get} alarm id: ${alarmFilter.get.alarmId} system mode: ${alarmFilter.get.systemMode.get}")
      }
      if (!frequencyIsAlright && alarmFilter.get.status.get == AlarmNotificationStatuses.IGNORED) {
        frequencyIsAlright = IsIgnoredExpired(alarmFilter.get.expiresAt.get)
      }
    }
    frequencyIsAlright
  }

  /**
    * Checks if a ISODAte string in UTC has expired by comparing it to current date time. It returns true if expired,
    * returns false otherwise.
    **/
  def IsIgnoredExpired(expirationDate: String): Boolean = {
    val current = DateTime.now(DateTimeZone.UTC).getMillis
    val d = DateTime.parse(expirationDate).getMillis
    if ((current - d) > 0) true
    else false
  }

}
