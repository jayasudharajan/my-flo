package MicroService

import Utils.ApplicationSettings
import com.flo.Enums.Notifications.DeliveryMediums
import com.flo.Models.ICDAlarmNotificationGraveyardTime
import com.typesafe.scalalogging.LazyLogging

class GraveyardTimeMicroService extends LazyLogging {

  private lazy val timeService = new TimeService()

  /**
    * Based on the notification router environmental variables settings an alarm can be blocked, depending on
    * DateTimeZone : dtz and medium it will return TRUE if graveyard shift is enabled and medium needs to be blocked it
    * will return false otherwise.
    **/
  def isItGraveyardTime(dtz: String, medium: Int, gTime: Option[ICDAlarmNotificationGraveyardTime] = None): Boolean = {
    try {
      val graveyardTime: ICDAlarmNotificationGraveyardTime = getGraveyardTime(gTime)

      val isGraveYard: Boolean = if (graveyardTime.enabled) {

        val localTime: String = {
          val t = timeService.getCurrentLocalTime(dtz)
          s"${t.getHourOfDay}:${t.getMinuteOfHour}"
        }

        localTime match {
          case nightIsStillYoung if TLtT2(localTime, graveyardTime.startTimeIn24Format) && (localTime == graveyardTime.endsTimeIn24Format || TGrtT2(localTime, graveyardTime.endsTimeIn24Format)) =>
            logger.info(s"graveyard filter: nightIsStillYoung stz: $dtz")
            false
          case graveyardShift if (localTime == graveyardTime.startTimeIn24Format || TGrtT2(localTime, graveyardTime.startTimeIn24Format)) && TLtT2(localTime, graveyardTime.endsTimeIn24Format) =>
            logger.info(s"graveyard filter: graveyardShift stz: $dtz")

            true
          case graveYardInTwoDaysCaseOne if (TGrtT2(localTime, graveyardTime.startTimeIn24Format) && TLtT2(graveyardTime.startTimeIn24Format, graveyardTime.endsTimeIn24Format)) && TGrtT2(localTime, graveyardTime.endsTimeIn24Format) =>
            logger.info(s"graveyard filter: graveYardInTwoDaysCaseOne stz: $dtz")

            false
          case graveYardInTwoDaysCaseTwo if (TLtT2(localTime, graveyardTime.startTimeIn24Format) && TGrtT2(graveyardTime.startTimeIn24Format, graveyardTime.endsTimeIn24Format)) && TLtT2(localTime, graveyardTime.endsTimeIn24Format) =>
            logger.info(s"graveyard filter: graveYardInTwoDaysCaseTwo stz: $dtz")

            true
          case graveYardInTwoDaysCaseThree if (TGrtT2(localTime, graveyardTime.startTimeIn24Format) && TGrtT2(graveyardTime.startTimeIn24Format, graveyardTime.endsTimeIn24Format)) && TGrtT2(localTime, graveyardTime.endsTimeIn24Format) =>
            logger.info(s"graveyard filter: graveYardInTwoDaysCaseThree stz: $dtz")
            true
          case _ =>
            logger.info(s"graveyard filter: wildcard case stz: $dtz")

            false
        }
      } else {
        logger.info("graveyard time has been disabled")
        false
      }
      val isMediumEnabledDuringGraveyardShift: Boolean = {
        medium match {
          case DeliveryMediums.PUSH_NOTIFICATION =>
            graveyardTime.sendPushNotification
          case DeliveryMediums.SMS =>
            graveyardTime.sendSms
          case DeliveryMediums.EMAIL =>
            graveyardTime.sendEmail
          case _ => false
        }
      }
      if (isGraveYard && !isMediumEnabledDuringGraveyardShift)
        true
      else if (isGraveYard && isMediumEnabledDuringGraveyardShift) {
        logger.info(s"Graveyard exempt for medium: $medium")
        false
      }
      else {
        logger.info("It is not graveyard time yet....")
        false
      }

    }
    catch {
      case e: Throwable =>
        logger.error(s"The Following exception was thrown trying to set graveyard Settings ${e.toString}")
        false
    }
  }

  /**
    * This method is a greater than operator for 24 hour format strings 'HH:MM', check if t is greater than t2
    **/
  private def TGrtT2(t: String, t2: String): Boolean = {

    val startTime = t.split(":")
    val startTimeHour: Int = startTime(0).toInt
    val startMinute: Int = startTime(1).toInt
    //t2
    val startTime2 = t2.split(":")
    val startTimeHour2: Int = startTime2(0).toInt
    val startMinute2: Int = startTime2(1).toInt

    if (startTimeHour > startTimeHour2) {
      true
    }
    else if (startTimeHour == startTimeHour2) {
      if (startMinute > startMinute2) {
        true
      }
      else false
    }
    else false


  }

  /**
    * This method is a less than operator for 24 hour format strings 'HH:MM', check if t is less than t2
    **/
  private def TLtT2(t: String, t2: String): Boolean = {

    val startTime = t.split(":")
    val startTimeHour: Int = startTime(0).toInt
    val startMinute: Int = startTime(1).toInt
    //t2
    val startTime2 = t2.split(":")
    val startTimeHour2: Int = startTime2(0).toInt
    val startMinute2: Int = startTime2(1).toInt

    if (startTimeHour < startTimeHour2) {
      true
    }
    else if (startTimeHour == startTimeHour2) {
      if (startMinute < startMinute2) {
        true
      }
      else false
    }
    else false


  }

  /**
    * This function will return the global default graveyard time it will return the one passed otherwise.
    **/
   def getGraveyardTime(gt: Option[ICDAlarmNotificationGraveyardTime]): ICDAlarmNotificationGraveyardTime = gt match {
    case Some(g) => g
    case _ =>
      ICDAlarmNotificationGraveyardTime(
        startTimeIn24Format = ApplicationSettings.flo.graveyardTime.startsHourOfTheDay.getOrElse(throw new Exception("No start time found for graveyard in configuration or env vars")),
        endsTimeIn24Format = ApplicationSettings.flo.graveyardTime.endsHourOfTheDay.getOrElse(throw new Exception("No end time was found for graveyard in configuration or env vars")),
        sendEmail = CanMediumSendDuringGraveYardShift(DeliveryMediums.EMAIL),
        sendSms = CanMediumSendDuringGraveYardShift(DeliveryMediums.SMS),
        sendPushNotification = CanMediumSendDuringGraveYardShift(DeliveryMediums.PUSH_NOTIFICATION),
        enabled = ApplicationSettings.flo.graveyardTime.enabled
      )
  }

  /**
    * based on notification-router environmnetal varaibles settings a medium can bypass graveyardshift, if a medium is
    * exempted from graveyard it will return true, otherwise if a medium is not exempted or not found in application
    * settings it will return false.
    **/
  def CanMediumSendDuringGraveYardShift(medium: Int): Boolean = medium match {
    case DeliveryMediums.PUSH_NOTIFICATION =>
      ApplicationSettings.flo.graveyardTime.sendAppNotifications
    case DeliveryMediums.EMAIL =>
      ApplicationSettings.flo.graveyardTime.sendEmails
    case DeliveryMediums.SMS =>
      ApplicationSettings.flo.graveyardTime.sendSMS
    case _ =>
      logger.warn(s"Medium's setting for graveyard were not found medium enum: $medium")
      false
  }

}
