package MicroService

import Utils.ApplicationSettings
import com.flo.Enums.Notifications.AlarmNotificationStatuses
import com.flo.Models.{AlarmNotificationDeliveryFilters, ICDAlarmNotificationGraveyardTime}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ScheduledNotificationInfo, UserActivityEvent}
import com.flo.Models.KafkaMessages.{ICDAlarmIncident, Schedule, Task}
import org.joda.time.{DateTime, DateTimeZone}
import argonaut.Argonaut._
import com.flo.Models.Users.UserContactInformation
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}

import scala.util.Try

/**
  * Created by Francisco on 5/18/2017.
  */
class ScheduledNotificationService {


  lazy val cipher = new FLOCipher
  lazy val keyProvider = new S3RSAKeyProvider(
    ApplicationSettings.cipher.keyProvider.bucketRegion,
    ApplicationSettings.cipher.keyProvider.bucketName,
    ApplicationSettings.cipher.keyProvider.keyPathTemplate
  )
  lazy val rotationStrategy = new KeyIdRotationStrategy
  lazy val encryptionPipeline = new EncryptionPipeline(cipher, keyProvider, rotationStrategy)
  lazy val graveyardTimeMicroService = new GraveyardTimeMicroService()
  lazy val timeService = new TimeService()

  def scheduledDeliveryTime(dtz: String, gTime: Option[ICDAlarmNotificationGraveyardTime]): String = {
    val graveyardTime: ICDAlarmNotificationGraveyardTime = graveyardTimeMicroService.getGraveyardTime(gTime)
    val endTime = graveyardTime.endsTimeIn24Format.split(":")
    val endTimeHour = endTime(0).toInt
    val endTimeMin = endTime(1).toInt
    val time = timeService.getCurrentLocalTime(dtz)
    val scheduledTime = time
    if (time.getHourOfDay < endTimeHour)
      scheduledTime.withHourOfDay(endTimeHour).toDateTime(DateTimeZone.UTC).toDateTimeISO.toString
    else
      scheduledTime.plusDays(1).withHourOfDay(endTimeHour).toDateTime(DateTimeZone.UTC).toDateTimeISO.toString
  }

  def getScheduledMediums(dtz: String, mediums: Array[Int], gTime: Option[ICDAlarmNotificationGraveyardTime] = None): Set[Int] = {
    var scheduledMediums = Set[Int]()
    mediums.foreach(m => {
      if (graveyardTimeMicroService.isItGraveyardTime(dtz, m, gTime))
        scheduledMediums += m
    })
    scheduledMediums
  }

  def getDeliveryMediums(mediums: Option[Set[Int]], scheduledNotificationInfo: Option[ScheduledNotificationInfo] = None): Set[Int] = scheduledNotificationInfo match {
    case None =>
      mediums.getOrElse(Set[Int]())
    case Some(scheduledNotification) =>
      scheduledNotification.mediums.getOrElse(Set[Int]())
  }

  def processAlarmNotificationDeliveryFilter(filter: Option[AlarmNotificationDeliveryFilters]): Try[Int] = filter match {
    case resolved if resolved.get.status.get == AlarmNotificationStatuses.RESOLVED =>
      Try(AlarmNotificationStatuses.RESOLVED)
    case ignored if ignored.get.status.get == AlarmNotificationStatuses.IGNORED =>
      Try(AlarmNotificationStatuses.IGNORED)
    case unresolved if unresolved.get.status.get == AlarmNotificationStatuses.UNRESOLVED =>
      Try(AlarmNotificationStatuses.UNRESOLVED)
    case None =>
      throw new IllegalArgumentException("filter cannot empty")
    case _ =>
      throw new Exception("filter could not be process unknown exception happned")
  }

  def incidentMessageGenerator(incident: ICDAlarmIncident, scheduledMediums: Set[Int], scheduledDeliveryTime: String, incidentRegistryId: String, userInfo: UserContactInformation, userActivity: Option[UserActivityEvent] = None): ICDAlarmIncident = {

    ICDAlarmIncident(
      id = incident.id,
      ts = incident.ts,
      deviceId = incident.deviceId,
      data = incident.data,
      scheduledNotificationInfo = Some(ScheduledNotificationInfo(
        scheduledAt = DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString(),
        scheduledDeliveryTime,
        mediums = Some(scheduledMediums),
        incidentRegistryId,
        userInfo.userId.getOrElse("")
      )),
      userActivityEvent = userActivity
    )

  }

  def scheduledTaskKafkaMessage(incident: ICDAlarmIncident, icdId: String, suffix: Option[String] = None): Task = {
    val scheduledDeliveryTime = new DateTime(incident.scheduledNotificationInfo.get.scheduledDeliveryTime, DateTimeZone.UTC)
    val snapshot = incident.data.snapshot
    val alarm = incident.data.alarm
    Task(
      destinationTopic = ApplicationSettings.kafka.topic.get,
      taskData = incident.asJson.nospaces.toString,
      schedule = Schedule(
        id = generateScheduledTaskId(icdId, alarm.alarmId, snapshot.systemMode.get, suffix),
        name = Some("scheduled-notification"),
        expression = convertUTCtoCronTime(scheduledDeliveryTime),
        timezone = "Etc/UTC",
        calendar = None,
        startDate = None
      ),
      metadata = None,
      shouldOverride = Some(true)
    )
  }

  def encryptScheduledTaskData(incident: ICDAlarmIncident): String = {
    if (ApplicationSettings.kafka.encryption) {
      encryptionPipeline.encrypt(ApplicationSettings.cipher.keyProvider.keyId, incident.asJson.nospaces)
    } else {
      incident.asJson.nospaces
    }
  }

  def generateScheduledTaskId(icdId: String, alarmId: Int, systemMode: Int, suffix: Option[String] = None): String = suffix match {
    case None =>
      s"$icdId-$alarmId-$systemMode"
    case Some(suf) =>
      s"$suf-$icdId-$alarmId-$systemMode"
  }

  def convertUTCtoCronTime(d: DateTime): String = {
    val secondOfTheMinute = d.getSecondOfMinute
    val minuteOfTheHour = d.getMinuteOfHour
    val hourOfTheDay = d.getHourOfDay
    val dayOfTheMonth = d.getDayOfMonth
    val monthOfTheYear = d.getMonthOfYear
    val year = d.getYear
    s"$secondOfTheMinute $minuteOfTheHour $hourOfTheDay $dayOfTheMonth $monthOfTheYear ? $year"

  }


}
