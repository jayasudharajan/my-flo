package MicroService

import com.flo.Enums.Notifications.MaxDeliveryAmountScope
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ScheduledNotificationInfo
import com.flo.utils.TimestampCompatibilityHelpers
import com.typesafe.scalalogging.LazyLogging
import org.joda.time.{DateTime, DateTimeZone}

/**
  * Created by Francisco on 7/3/2017.
  */
class TimeService extends LazyLogging {

  def convertUTCtoLosAngeles(utc: String): String = {
    new DateTime(utc, DateTimeZone.forID("America/Los_Angeles")).toDateTimeISO.toString(TimeFormat.MM_DD_HH_MM_A)
  }

  def ConvertUTCToLocalTImeZone(utcDate: String, dtz: String, timeFormat: String): String = {
    var date = new DateTime(utcDate, DateTimeZone.forID(dtz)).toString(timeFormat)
    date = date replaceAllLiterally("AM", "am")
    date = date replaceAllLiterally("PM", "pm")
    date
  }

  def convertSecondsToMinutesAsString(seconds: Option[Int]): String = seconds match {
    case Some(sec) =>
      BigDecimal(sec)./(BigDecimal(60)).setScale(1, BigDecimal.RoundingMode.HALF_UP).toString()
    case _ =>
      "N/A"
  }

  /**
    * Python epoch seems to eliminate the full Long value, it eliminates the zeros to the right, this functions adds
    * those zeros back the way Joda Function Expects them so our epoch to ISO date converter works well.
    **/
  def epochTimeStampToStringISODate(epoch: Option[Long]): String = epoch match {
    case Some(ts) =>
      val d = new DateTime(TimestampCompatibilityHelpers.toMillisecondsTimestamp(ts), DateTimeZone.UTC)
      if (d.getYear < DateTime.now(DateTimeZone.UTC).minusYears(2).getYear || d.getYear > DateTime.now(DateTimeZone.UTC).plusYears(2).getYear)
        throw new Exception("invalid time" + d.toDateTimeISO.toString() + " ts received " + ts.toString)
      d.toDateTimeISO.toString()
    case _ => throw new IllegalArgumentException("ts cannot be absent")
  }

  def getCurrentTimeInISODateUTC(): String = DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()

  def getCurrentTimeInISODateUTCPlus(years: Int = 0, days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) = DateTime.now(DateTimeZone.UTC).plusYears(years).plusDays(days).plusHours(hours).plusMinutes(minutes).plusSeconds(seconds).toDateTimeISO.toString()

  /**
    * Using the DateTimeZone it returns a Joda.DateTime object based on the Datetimezone id passed
    **/
  def getCurrentLocalTime(locTimeZone: String): DateTime = {
    val timezone = DateTimeZone.forID(locTimeZone)
    DateTime.now(timezone)
  }

  /**
    * This methods helps determine the delivery interval for a notification based on the filter settings alarms have.
    **/
  def deliveryIntervalsInMilliSecondsGenerator(scope: Int, units: Int): Long = scope match {
    case MaxDeliveryAmountScope.BI_WEEK =>
      //Milliseconds in a week  = 604800000 BiWeekly = 2 times that
      (604800000 * 2).*(units).toLong
    case MaxDeliveryAmountScope.DAY =>
      //Miliseconds in a day 86400000
      86400000.*(units).toLong
    case MaxDeliveryAmountScope.HOURS =>
      //Milliseconds in an hour  = 3600000
      3600000.*(units).toLong
    case MaxDeliveryAmountScope.MINUTES =>
      //Milliseconds in a minute
      60000.*(units).toLong
    case MaxDeliveryAmountScope.WEEK =>
      //Milliseconds in a week = 604800000
      604800000.*(units).toLong
    case MaxDeliveryAmountScope.MONTH =>
      // A assuming a month is 30 days
      (86400000 * 30).*(units).toLong
    case MaxDeliveryAmountScope.YEAR =>
      /*
        1 day = 24 hours
        1 hour = 60 minutes
        1 minute = 60 seconds
        1 second = 1000 milliseconds
        365*24*60*60*1000 = 31,536,000,000 milliseconds
         */
      "31536000000".toLong.*(units.toLong)
    case _ =>
      //worst case we send every three hours
      10800000.toLong
  }


  /**
    * This features prevents to send replayed messages from kafka
    **/
  def tooMuchTimeElapsedSinceIncidentValidator(incidentTime: Long, maxMinutesElapsedSinceIncident: Int, scheduledNotificationInfo: Option[ScheduledNotificationInfo] = None): Boolean = scheduledNotificationInfo match {
    case None =>
      val currentTime: Long = DateTime.now(DateTimeZone.UTC).getMillis
      if ((currentTime - incidentTime) > maxMinutesElapsedSinceIncident.*(60000.toLong))
        true
      else
        false

    case Some(scheduledNotification) =>
      val scheduledDeliveryTimeInMilliSeconds: Long = new DateTime(scheduledNotification.scheduledDeliveryTime, DateTimeZone.UTC).getMillis

      val currentTime: Long = DateTime.now(DateTimeZone.UTC).getMillis
      if ((currentTime - scheduledDeliveryTimeInMilliSeconds) > maxMinutesElapsedSinceIncident.*(60000.toLong))
        true
      else
        false
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


object TimeFormat extends Enumeration {

  type TimeFormat = Value
  val YYYY_MM_DD_HH_MM_A = "yyyy-MM-dd hh:mm a"
  val MM_DD_HH_MM_A = "MMMM dd h:mm a"

}