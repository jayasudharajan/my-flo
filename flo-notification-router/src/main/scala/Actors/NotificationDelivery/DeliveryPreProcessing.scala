package Actors.NotificationDelivery

import MicroService.Lognators.DeliveryPreProcessingLognator
import MicroService._
import Models.CustomerService.RegularCSEmailForUserAlert
import Models.Mediums._
import Nators.AlarmNotificationDeliveryFiltersGenerators
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.{AlarmNotificationStatuses, DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2._
import com.flo.FloApi.v3.{NotificationTokenEndpoints => NotificationTokenEndpointsV3}
import com.flo.Models.Logs.ICDAlarmIncidentRegistryLog
import com.flo.Models.Users.UserContactInformation
import com.flo.Models.{AlarmNotificationDeliveryFilters, AppDeviceNotificationInfo, NotificationToken}
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}


class DeliveryPreProcessing(producer: ActorRef, choreographer: ActorRef, customerService: ActorRef) extends Actor with ActorLogging {

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()


  private lazy val proxyAlarmFilters = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyIcdAlarmIncidentRegistryLog = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyAppDeviceInfo = new AppDeviceNotificationInfoEnpoints(clientCredentialsTokenProvider)
  private lazy val proxyUserNotificationTokens = new NotificationTokenEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyUserNotificationTokensV3 = new NotificationTokenEndpointsV3(clientCredentialsTokenProvider)
  private lazy val proxyUserInfo = new UserContactInformationEndpoints(clientCredentialsTokenProvider)

  //nators
  private lazy val filterNator = new AlarmNotificationDeliveryFiltersGenerators()

  // services
  private lazy val alertService = new AlertService(context)
  private lazy val timeService = new TimeService()
  private lazy val scheduledNotificationsService = new ScheduledNotificationService()
  private lazy val lognator = new DeliveryPreProcessingLognator()
  private lazy val enumsToStringService = new EnumsToStringService()
  private lazy val graveyardTimeMicroService = new GraveyardTimeMicroService()
  private lazy val iCDAlarmNotificationDeliveryRuleService = new ICDAlarmNotificationDeliveryRuleService()
  private lazy val notificationTokenService = new NotificationTokenMicroService()


  //general
  private lazy val API_URL = ApplicationSettings.flo.api.url.getOrElse(throw new Exception("FLO_API_URL was not found in config nor env vars"))

  override def postStop(): Unit = {
    context.children foreach { child =>
      context.unwatch(child)
      context.stop(child)
    }
    log.info(s" I ${self.toString()}  be 💀☠👻 ")
    super.postStop()
  }

  def receive = {
    case preProcessingMessage: PreProcessingMessage =>
      val logMessage = lognator.incidentLogMessage(preProcessingMessage)

      if (preProcessingMessage.hasUsersMutedAlarm) {
        mutedFilter(preProcessingMessage)
        log.info(s"Alert has been muted by user $logMessage")
        registryLogForMuted(preProcessingMessage.createIcdIncidentRegistryRecord.get.id, preProcessingMessage.userRules.userId, logMessage)
      }
      else {
        val status: Int = alertService.getFilterStatusByAlertSeverityAndIsAlarmAutoLogAndIsAlarmMuted(preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.severity.get, preProcessingMessage.icdAlarmNotificationDeliveryRules.get.internalId, preProcessingMessage.hasUsersMutedAlarm, preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.status.get)
        for {
          appDeviceInfo <- proxyAppDeviceInfo.GetByUserIdAndIcdId(preProcessingMessage.userRules.userId, preProcessingMessage.iCD.get.id.get) recoverWith {
            case e: Throwable =>
              log.error(e, s"appDeviceInfo log message: $logMessage")
              throw e
          }
          userInfo <- proxyUserInfo.GetPlusEmail(preProcessingMessage.userRules.userId) recoverWith {
            case e: Throwable =>
              log.error(e, s"userInfo log message $logMessage")
              throw e
          }
          notificationTokensV2 <- proxyUserNotificationTokensV3.GetTokens(preProcessingMessage.userRules.userId) recoverWith {
            case e: Throwable =>
              log.error(s"noticationTokens ${e.toString}")
              throw e
          }
          notificationTokensV1 <- proxyUserNotificationTokens.Get(preProcessingMessage.userRules.userId) recoverWith {
            case e: Throwable =>
              log.error(e, s"notificationTokens log message: $logMessage")
              throw e
          }
        } yield {
          var notificationTokens = notificationTokensV1
          if (notificationTokensV2.isDefined && notificationTokensV2.nonEmpty && notificationTokensV2.get.nonEmpty) {
            log.info(s"tokens v2 found for : $logMessage")
            notificationTokens = notificationTokenService.getNotificationTokensFromV2ToV1(notificationTokensV2.get)
          }

          status match {

            case AlarmNotificationStatuses.UNRESOLVED | AlarmNotificationStatuses.RESOLVED =>
              log.info(s"Alarm is in ${enumsToStringService.alarmNotificationStatusesToString(status)} state  log message $logMessage")

              //save new filter status
              saveNewFilterStatusForReSolvedAndUnresolved(preProcessingMessage)

              if (!preProcessingMessage.hasUsersMutedAlarm) {

                deliverNotifications(preProcessingMessage, notificationTokens, userInfo, appDeviceInfo)
                validateData(preProcessingMessage)
              }

            case AlarmNotificationStatuses.IGNORED =>
              val isExpired = timeService.IsIgnoredExpired(preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.expiresAt.get)
              if (isExpired && !preProcessingMessage.hasUsersMutedAlarm) {
                log.info(s"Alarm is in expired state  log message $logMessage")

                filterPutForIgnoreStatus(preProcessingMessage)
                deliverNotifications(preProcessingMessage, notificationTokens, userInfo, appDeviceInfo)
                validateData(preProcessingMessage)

              }
              if (!isExpired) {
                log.info(s"Alarm is in ignored state  log message $logMessage")
                filterPatchForIgnoredStatus(preProcessingMessage)
                incidentRegistryLogForIgnore(preProcessingMessage)
                zendeskTicketnator(preProcessingMessage, userInfo)
              }

            case AlarmNotificationStatuses.MUTED =>
              log.info(s"Alarm is in muted state  log message $logMessage")

              mutedFilter(preProcessingMessage)
              zendeskTicketnator(preProcessingMessage, userInfo)
          }


        }
      }

  }

  private def mutedFilter(preProcessingMessage: PreProcessingMessage): Unit = {
    proxyAlarmFilters.Put(Some(AlarmNotificationDeliveryFilters(
      icdId = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.icdId,
      alarmId = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.alarmId,
      systemMode = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.systemMode,
      createdAt = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.createdAt,
      updatedAt = Some(timeService.getCurrentTimeInISODateUTC()),
      expiresAt = Some(timeService.getCurrentTimeInISODateUTCPlus(100)),
      lastDecisionUserId = Some(preProcessingMessage.userRules.userId),
      status = Some(AlarmNotificationStatuses.MUTED),
      lastIcdAlarmIncidentRegistryId = Some(preProcessingMessage.createIcdIncidentRegistryRecord.get.id),
      incidentTime = Some(preProcessingMessage.createIcdIncidentRegistryRecord.get.incidentTime),
      severity = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.severity
    ))).onComplete {
      case Success(s) => log.info(s"mutedFilter AlarmNotificationDeliveryFilter was updated successfully as Filtered icd: ${preProcessingMessage.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} log message ${lognator.incidentLogMessage(preProcessingMessage)}")
      case Failure(e) => log.error(e, s"mutedFilter log message: ${lognator.incidentLogMessage(preProcessingMessage)}")
    }

  }

  private def incidentRegistryLogForIgnore(preProcessingMessage: PreProcessingMessage): Unit = {
    proxyIcdAlarmIncidentRegistryLog.Post(Some(
      ICDAlarmIncidentRegistryLog(
        id = Some(makeId()),
        createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
        icdAlarmIncidentRegistryId = Some(preProcessingMessage.createIcdIncidentRegistryRecord.get.id),
        userId = preProcessingMessage.ultimateAlarmNotificationDeliveryFilters.lastDecisionUserId,
        deliveryMedium = Some(DeliveryMediums.FILTERED),
        status = Some(ICDAlarmIncidentRegistryLogStatus.NONE),
        receiptId = Some(makeId())
      )

    )).onComplete {
      case Success(s) => log.info(s"incidentRegistryLogForIgnore ICDALARMINCIDENTREGISTRYLOG was created successfully as Filtered icd: ${preProcessingMessage.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} log message: ${lognator.incidentLogMessage(preProcessingMessage)}")
      case Failure(e) => log.error(e, s"incidentRegistryLogForIgnore log message ${lognator.incidentLogMessage(preProcessingMessage)}")
    }
  }

  private def filterPutForIgnoreStatus(msg: PreProcessingMessage): Unit = {
    proxyAlarmFilters.Put(Some(AlarmNotificationDeliveryFilters(
      icdId = msg.iCD.get.id,
      alarmId = Some(msg.icdAlarmNotificationDeliveryRules.get.alarmId),
      systemMode = Some(msg.icdAlarmNotificationDeliveryRules.get.systemMode),
      createdAt = msg.ultimateAlarmNotificationDeliveryFilters.createdAt,
      updatedAt = Some(timeService.getCurrentTimeInISODateUTC()),
      expiresAt = Some(timeService.getCurrentTimeInISODateUTCPlus(100)),
      lastDecisionUserId = msg.ultimateAlarmNotificationDeliveryFilters.lastDecisionUserId,
      status = Some(AlarmNotificationStatuses.UNRESOLVED),
      lastIcdAlarmIncidentRegistryId = Some(msg.createIcdIncidentRegistryRecord.get.id),
      incidentTime = Some(msg.createIcdIncidentRegistryRecord.get.incidentTime),
      severity = msg.ultimateAlarmNotificationDeliveryFilters.severity
    ))).onComplete {
      case Success(updatedAlarmNotificationDeliveryFilters) => log.info(s"Updated the status of notification from SOLVED to UNRESOLVED ${msg.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${msg.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${msg.icdAlarmNotificationDeliveryRules.get.systemMode}")
      case Failure(err) => log.error(s"For ${msg.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${msg.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${msg.icdAlarmNotificationDeliveryRules.get.systemMode} The following exception happened trying to update alarmnotificationdeliveryfilters record  to UNRESOLVED : ${err.toString}")
    }
  }

  /**
    * This method will do an update of the updated_at field for the filter for when the ignore filter is still valid. It is important to trigger it so the internal reports see devices with ignore filters for alerts.
    **/
  private def filterPatchForIgnoredStatus(msg: PreProcessingMessage): Unit = {
    proxyAlarmFilters.Put(
      Some(
        msg.ultimateAlarmNotificationDeliveryFilters.copy(
          updatedAt = Some(
            timeService.getCurrentTimeInISODateUTC()
          ),
          lastIcdAlarmIncidentRegistryId = Some(msg.createIcdIncidentRegistryRecord.get.id),
          incidentTime = Some(msg.createIcdIncidentRegistryRecord.get.incidentTime)
        )
      )
    )
  }


  private def validateData(preProcessingMessage: PreProcessingMessage): Unit = {
    val validationService = new ValidationService()
    val snapshot = preProcessingMessage.icdAlarmIncidentMessage.data.snapshot

    validationService.snapshotLavishValidation(snapshot, preProcessingMessage.iCD.get.deviceId.get)
    validationService.userAlarmNotificationDeliveryRulesLavishValidation(preProcessingMessage.userRules, preProcessingMessage.iCD.get.deviceId.get)
    validationService.icdLavishValidation(preProcessingMessage.iCD.get)
    validationService.icdAlarmNotificationDeliveryRulesLavishValidation(preProcessingMessage.icdAlarmNotificationDeliveryRules.get)
    validationService.iCDAlarmIncidentLavishValidation(preProcessingMessage.icdAlarmIncidentMessage)
  }

  private def saveNewFilterStatusForReSolvedAndUnresolved(preProcessingMessage: PreProcessingMessage): Unit = {

    val status: Int = if (alertService.isAlarmAutoLog(preProcessingMessage.icdAlarmNotificationDeliveryRules.get.internalId) || alertService.isAlarmInfoLevel(preProcessingMessage.icdAlarmNotificationDeliveryRules.get.severity)) AlarmNotificationStatuses.RESOLVED else AlarmNotificationStatuses.UNRESOLVED

    proxyAlarmFilters.Put(item = Some(
      filterNator.PutForResolvedAndUnresolved(preProcessingMessage.ultimateAlarmNotificationDeliveryFilters, preProcessingMessage.snapshot, preProcessingMessage.createIcdIncidentRegistryRecord.get.id, preProcessingMessage.createIcdIncidentRegistryRecord.get.incidentTime, status)
    )).onComplete {
      case Success(updatedAlarmNotificationDeliveryFilters) => log.info(s"Updated the status of notification from SOLVED to UNRESOLVED ${preProcessingMessage.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode}")
      case Failure(err) => log.error(s"For ${preProcessingMessage.iCD.get.id.getOrElse(s"N/A")} alarm ID: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} The following exception happened trying to update alarmnotificationdeliveryfilters record  to UNRESOLVED : ${err.toString}")
    }
  }

  private def registryLogForMuted(incidentId: String, userId: String, logMsg: String): Unit = {
    proxyIcdAlarmIncidentRegistryLog.Post(
      Some(
        ICDAlarmIncidentRegistryLog(
          id = Some(makeId()),
          createdAt = Some(timeService.getCurrentTimeInISODateUTC()),
          icdAlarmIncidentRegistryId = Some(incidentId),
          userId = Some(userId),
          deliveryMedium = Some(DeliveryMediums.FILTERED),
          status = Some(ICDAlarmIncidentRegistryLogStatus.MUTEDBYUSER),
          receiptId = Some(makeId())
        )
      )
    ).onComplete {
      case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully for incident id : $incidentId MUTEDBYUSER log message $logMsg")
      case Failure(e) => log.error(e, s"registryLogForMuted log messsage $logMsg")
    }
  }

  private def zendeskTicketnator(preProcessingMessage: PreProcessingMessage, userInfo: Option[UserContactInformation]): Unit = {

    if (preProcessingMessage.icdAlarmIncidentMessage.scheduledNotificationInfo.isEmpty && !preProcessingMessage.isUserTenant) {
      log.info(s"sending email to CS for log message: ${lognator.incidentLogMessage(preProcessingMessage)}")
      regularCSEmailForUserAlertGenerator(preProcessingMessage, userInfo)
    } else {
      log.info(lognator.zendeskEmailNotSent(preProcessingMessage))
    }

  }

  private def deliverNotifications(preProcessingMessage: PreProcessingMessage, notificationTokens: Option[NotificationToken], userInfo: Option[UserContactInformation], appDeviceInfo: Option[Set[AppDeviceNotificationInfo]]): Unit = {

    //CS Email
    zendeskTicketnator(preProcessingMessage, userInfo)
    //CS Email ends

    val isScheduled = if (preProcessingMessage.icdAlarmIncidentMessage.scheduledNotificationInfo.isDefined && preProcessingMessage.icdAlarmIncidentMessage.scheduledNotificationInfo.nonEmpty) true else false
    val mediums: Set[Int] = if (isScheduled) {
      preProcessingMessage.icdAlarmIncidentMessage.scheduledNotificationInfo.get.mediums.getOrElse(Set[Int]())
    }
    else {
      preProcessingMessage.userRules.optional.getOrElse(Set[Int]())
    }
    mediums.foreach {
      case DeliveryMediums.VOICE => //woice is especial

        if (!isScheduled) {
          log.info(s"preparing message type voice for alarm id : ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} device id : ${preProcessingMessage.iCD.get.deviceId.getOrElse("N/A")}")

          val scheduledIncidentForVoice = scheduledNotificationsService.incidentMessageGenerator(preProcessingMessage.icdAlarmIncidentMessage, Set[Int](DeliveryMediums.VOICE), DateTime.now(DateTimeZone.UTC).plusSeconds(30).toDateTimeISO.toString(), preProcessingMessage.createIcdIncidentRegistryRecord.get.id, userInfo.get)
          val scheduledCall = scheduledNotificationsService.scheduledTaskKafkaMessage(scheduledIncidentForVoice, preProcessingMessage.iCD.get.id.get, Some("woice"))
          producer ! scheduledCall
        }
        else {
          choreographer ! FloiceActorMessage(
            userInfo.get,
            preProcessingMessage.createIcdIncidentRegistryRecord.get,
            Some(preProcessingMessage.icdLocation),
            preProcessingMessage.icdAlarmNotificationDeliveryRules.get,
            preProcessingMessage.icdAlarmIncidentMessage.data.snapshot,
            preProcessingMessage.isUserTenant,
            preProcessingMessage.isUserLandLord,
            preProcessingMessage.unitSystem
          )
        }


      case DeliveryMediums.PUSH_NOTIFICATION =>
        log.info(s"preparing message type Push Notification for alarm id : ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} device id : ${preProcessingMessage.iCD.get.deviceId.getOrElse("N/A")}")

        if (!graveyardTimeMicroService.isItGraveyardTime(preProcessingMessage.icdLocation.timezone.get, DeliveryMediums.PUSH_NOTIFICATION, preProcessingMessage.userRules.graveyardTime)) {
          choreographer ! PushNotificationChoreographerMessage(preProcessingMessage.userRules, preProcessingMessage.iCD, preProcessingMessage.icdAlarmNotificationDeliveryRules, preProcessingMessage.createIcdIncidentRegistryRecord, preProcessingMessage.icdAlarmIncidentMessage, Some(preProcessingMessage.icdLocation), appDeviceInfo, userInfo, notificationTokens, preProcessingMessage.unitSystem)

        } else {
          proxyIcdAlarmIncidentRegistryLog.Post(Some(ICDAlarmIncidentRegistryLog(
            id = Some(makeId()),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            icdAlarmIncidentRegistryId = Some(preProcessingMessage.icdAlarmIncidentMessage.id),
            userId = userInfo.get.userId,
            deliveryMedium = Some(DeliveryMediums.PUSH_NOTIFICATION),
            status = Some(ICDAlarmIncidentRegistryLogStatus.GRAVEYARDFILTERED),
            receiptId = Some(makeId())
          ))).onComplete {
            case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully for graveyard")
            case Failure(e) => log.error(e.toString)
          }
        }

      case DeliveryMediums.EMAIL =>

        log.info(s"preparing message type email for alarm id : ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} device id : ${preProcessingMessage.iCD.get.deviceId.getOrElse("N/A")}")

        if (!graveyardTimeMicroService.isItGraveyardTime(preProcessingMessage.icdLocation.timezone.get, DeliveryMediums.EMAIL, preProcessingMessage.userRules.graveyardTime)) {
          choreographer ! EmailChoreographerMessage(
            icdAlarmNotificationDeliveryRules = if (preProcessingMessage.isUserLandLord) iCDAlarmNotificationDeliveryRuleService.getLandlordRulesFromRegularRules(preProcessingMessage.icdAlarmNotificationDeliveryRules.get) else preProcessingMessage.icdAlarmNotificationDeliveryRules.get,
            preProcessingMessage.icdAlarmIncidentMessage,
            preProcessingMessage.createIcdIncidentRegistryRecord.get,
            preProcessingMessage.iCD,
            Some(preProcessingMessage.icdLocation),
            userInfo,
            preProcessingMessage.unitSystem
          )
        }
        else {
          proxyIcdAlarmIncidentRegistryLog.Post(Some(ICDAlarmIncidentRegistryLog(
            id = Some(makeId()),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            icdAlarmIncidentRegistryId = Some(preProcessingMessage.icdAlarmIncidentMessage.id),
            userId = userInfo.get.userId,
            deliveryMedium = Some(DeliveryMediums.EMAIL),
            status = Some(ICDAlarmIncidentRegistryLogStatus.GRAVEYARDFILTERED),
            receiptId = Some(makeId())
          ))).onComplete {
            case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully for graveyard")
            case Failure(e) => log.error(e.toString)
          }
        }


      case DeliveryMediums.SMS =>
        log.info(s"preparing message type sms for alarm id : ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.alarmId} system mode: ${preProcessingMessage.icdAlarmNotificationDeliveryRules.get.systemMode} device id : ${preProcessingMessage.iCD.get.deviceId.getOrElse("N/A")}")

        if (!graveyardTimeMicroService.isItGraveyardTime(preProcessingMessage.icdLocation.timezone.get, DeliveryMediums.SMS, preProcessingMessage.userRules.graveyardTime)) {

          choreographer ! SMSChoreographerMessage(
            preProcessingMessage.icdAlarmNotificationDeliveryRules.get,
            preProcessingMessage.icdAlarmIncidentMessage,
            preProcessingMessage.createIcdIncidentRegistryRecord.get,
            userInfo,
            preProcessingMessage.unitSystem
          )
        }
        else {
          proxyIcdAlarmIncidentRegistryLog.Post(Some(ICDAlarmIncidentRegistryLog(
            id = Some(makeId()),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            icdAlarmIncidentRegistryId = Some(preProcessingMessage.icdAlarmIncidentMessage.id),
            userId = userInfo.get.userId,
            deliveryMedium = Some(DeliveryMediums.SMS),
            status = Some(ICDAlarmIncidentRegistryLogStatus.GRAVEYARDFILTERED),
            receiptId = Some(makeId())
          ))).onComplete {
            case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully for graveyard")
            case Failure(e) => log.error(e.toString)
          }
        }
    }

    val scheduledMediums = scheduledNotificationsService.getScheduledMediums(preProcessingMessage.icdLocation.timezone.get, mediums.toArray, preProcessingMessage.userRules.graveyardTime)

    if (scheduledMediums.nonEmpty) {
      val scheduledIncident = scheduledNotificationsService.incidentMessageGenerator(preProcessingMessage.icdAlarmIncidentMessage, scheduledMediums, scheduledNotificationsService.scheduledDeliveryTime(preProcessingMessage.icdLocation.timezone.get, preProcessingMessage.userRules.graveyardTime), preProcessingMessage.createIcdIncidentRegistryRecord.get.id, userInfo.get)
      val scheduledIcdAlarmIncident = scheduledNotificationsService.scheduledTaskKafkaMessage(scheduledIncident, preProcessingMessage.iCD.get.id.get)
      producer ! scheduledIcdAlarmIncident

    }


  }

  private def regularCSEmailForUserAlertGenerator(preProcessingMessage: PreProcessingMessage, userInfo: Option[UserContactInformation]): Unit = {
    val snapshot = preProcessingMessage.icdAlarmIncidentMessage.data.snapshot
    customerService ! RegularCSEmailForUserAlert(
      preProcessingMessage.icdAlarmNotificationDeliveryRules,
      preProcessingMessage.iCD.get,
      userInfo,
      Some(preProcessingMessage.icdLocation),
      preProcessingMessage.createIcdIncidentRegistryRecord.get,
      preProcessingMessage.icdAlarmIncidentMessage,
      preProcessingMessage.userRules,
      preProcessingMessage.subscriptionInfo,
      Some(preProcessingMessage.unitSystem)
    )
  }

  private def makeId(): String = java.util.UUID.randomUUID().toString


}

object DeliveryPreProcessing {
  def props(producer: ActorRef, choreographer: ActorRef, customerService: ActorRef): Props = Props(classOf[DeliveryPreProcessing], producer, choreographer, customerService)
}
