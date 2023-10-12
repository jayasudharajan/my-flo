package Actors

import MicroService._
import MicroService.Email.EmailService
import Models.CustomerService.RegularCSEmailForUserAlert
import Models.ProducerMessages.ProducerEmailMessage
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, ActorSystem, Props}
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.Locale.UnitSystemEndpoints
import com.flo.FloApi.v2._
import com.flo.Models.{ICD, OnboardingEventDeviceInstalled}
import com.flo.Models.KafkaMessages.{EmailMessage, ICDAlarmIncident}
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{Await, Future}
import scala.util.{Failure, Success}
import scala.concurrent.duration._

/**
  * Created by Francisco on 7/13/2017.
  * This actor will take care of Customer service operations
  */
class CustomerService(producer: ActorRef) extends Actor with ActorLogging {

  implicit val materializer: ActorMaterializer = ActorMaterializer()(context)
  implicit val system: ActorSystem = context.system

  implicit val httpMetrics: HttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  private val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  private lazy val proxyAlarms = new ICDAlarmNotificationDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyUserContactInfo = new UserContactInformationEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyEventDeviceInstalled = new OnboardingEventEndpoints(clientCredentialsTokenProvider)
  private lazy val deviceInfoEndpoints = new com.flo.FloApi.v2.Analytics.ICDEndpoints(clientCredentialsTokenProvider)
  private lazy val unitSystemEndpoints = new UnitSystemEndpoints(clientCredentialsTokenProvider)

  //services

  private lazy val decisionEngineService = new DecisionEngineService(Await.result(unitSystemEndpoints.Get("default"), 10 seconds).get)
  private lazy val emailService = new EmailService()
  private lazy val csMicroService = new CSMicroService()
  private lazy val timeService = new TimeService()
  private lazy val deviceInfoMicroService = new DeviceInfoMicroService()
  private lazy val snapshotService = new SnapShotMicroService()

  private lazy val API_URL = ApplicationSettings.flo.api.url.getOrElse(throw new Exception("FLO_API_URL was not found in config nor env vars"))


  def receive = {
    case csAlarm: ICDAlarmIncident =>
      log.info(s"processing cs Alarm ${csAlarm.data.alarm.alarmId} for did: ${csAlarm.deviceId}")
      val deviceId = csAlarm.deviceId
      val snapshot = csAlarm.data.snapshot
      val alarm = csAlarm.data.alarm
      val telemetry = snapshotService.snapshotToTelemetryGenerator(snapshot)
      //get all meta data
      for {
        deviceInfo <- deviceInfoEndpoints.getDeviceInfo(deviceId) recoverWith {
          case e: Throwable =>
            log.error(s"deviceInfo for did: $deviceId exception: ${e.toString}")
            throw e
        }
        deviceInfoItem <- Future {
          deviceInfoMicroService.getDeviceInfoByDeviceId(deviceInfo, deviceId)
        } recoverWith {
          case e: Throwable =>
            log.error(e, s"getDeviceInfoByDeviceId for did $deviceId failed ")
            throw e
        }
        icd <- Future {
          deviceInfoMicroService.getICD(deviceInfoItem, snapshot)
        } recoverWith {
          case e: Throwable =>
            log.error(e, s"deviceInfoMicroService.getICD for did $deviceId failed ")
            throw e
        }
        icdUserIds <- Future {
          deviceInfoItem.users map (_.userId)
        }
        icdLocation <- Future {
          deviceInfoMicroService.getLocationFromGeoLocation(deviceInfoItem)
        } recoverWith {
          case e: Throwable =>
            log.error(e, s"getLocationFromGeoLocation for did $deviceId failed ")
            throw e
        }
        alarmDeliveryRules <- proxyAlarms.GetByAlarmIdAndBySystemMode(alarm.alarmId, snapshot.systemMode.get)

        userContact <- proxyUserContactInfo.GetPlusEmail(icdUserIds.head)
      } yield {
        val internalId = alarmDeliveryRules.map(_.internalId).getOrElse(-1)

        if(!decisionEngineService.isAlarmBlackListedForCSEmails(internalId)) {
          // convert meta data into Email feather message
          val emailFeather = emailService.CS5000Email(
            userContact,
            icdLocation,
            telemetry,
            alarmDeliveryRules,
            icdLocation.get.timezone.get,
            incidentTimeInUTC = timeService.epochTimeStampToStringISODate(Some(csAlarm.ts)),
            systemMode = snapshot.systemMode.get,
            icd
          )

          log.info(s"trying to send email for  cs Alarm ${csAlarm.data.alarm.alarmId} for did: ${csAlarm.deviceId}")
          producer ! emailFeather

          if(csAlarm.data.alarm.alarmId == CustomerService.installedAlert) {
            // trigger device install event
            deviceInstalledEvent(icd.get.deviceId.get)
          }
        } else {
          log.info(s"CS emails NOT send for incident id: ${csAlarm.id} device id: ${deviceId} alarm id : ${alarm.alarmId} system mode ${snapshot.systemMode}  are CS emails enabled: ${ApplicationSettings.cs.email.getOrElse(0).equals(1).toString}  is it test device: ${decisionEngineService.isTestIcd(deviceId)} is alarm black listed for CS: ${decisionEngineService.isAlarmBlackListedForCSEmails(internalId)}")
        }
      }

    case userAlert: RegularCSEmailForUserAlert =>

      if (ApplicationSettings.cs.email.getOrElse(0).equals(1) && !decisionEngineService.isTestIcd(userAlert.iCD.deviceId.get) && !decisionEngineService.isAlarmBlackListedForCSEmails(userAlert.icdAlarmNotificationDeliveryRules.get.internalId)) {
        producer ! regularCSEmailForUserAlertGenerator(userAlert)
        log.info(s"CS support email sent for incident id: ${userAlert.createIcdIncidentRegistryRecord.id} device id: ${userAlert.iCD.deviceId.get} alarm id : ${userAlert.userDeliveryRules.alarmId} system mode ${userAlert.userDeliveryRules.systemMode}")
      }
      else {
        log.info(s"CS emails NOT send for incident id: ${userAlert.createIcdIncidentRegistryRecord.id} device id: ${userAlert.iCD.deviceId.get} alarm id : ${userAlert.userDeliveryRules.alarmId} system mode ${userAlert.userDeliveryRules.systemMode}  are CS emails enabled: ${ApplicationSettings.cs.email.getOrElse(0).equals(1).toString}  is it test device: ${decisionEngineService.isTestIcd(userAlert.iCD.deviceId.get)} is alarm black listed for CS: ${decisionEngineService.isAlarmBlackListedForCSEmails(userAlert.icdAlarmNotificationDeliveryRules.get.internalId)}  ")
      }
  }

  private def deviceInstalledEvent(deviceId: String): Unit = {
    proxyEventDeviceInstalled.Post(Some(
      OnboardingEventDeviceInstalled(deviceId)
    )).onComplete {
      case Success(s) =>
        log.info(s"device installed event was successfully triggered for device id: $deviceId")
      case Failure(ex) =>
        log.error(ex, s"The Following error occurred trying to trigger device installed event for device id: $deviceId")
    }

  }

  def regularCSEmailForUserAlertGenerator(msg: RegularCSEmailForUserAlert): ProducerEmailMessage = {
    val snapshot = msg.incidentMessage.data.snapshot
    ProducerEmailMessage(
      csMicroService.csEmailGenerator(
        EmailMessage(
          id = Some(java.util.UUID.randomUUID().toString),
          ts = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          notificationTime = Some(timeService.epochTimeStampToStringISODate(Some(msg.incidentMessage.ts))),
          notification = msg.icdAlarmNotificationDeliveryRules,
          icd = Some(ICD(
            msg.iCD.deviceId,
            timeZone = snapshot.timeZone,
            systemMode = snapshot.systemMode,
            localTime = snapshot.localTime,
            id = msg.iCD.id,
            locationId = msg.iCD.locationId
          )),
          telemetry = snapshotService.snapshotToTelemetryGenerator(snapshot),
          userContactInformation = msg.userContactInformation,
          location = msg.icdLocation,
          statusCallback = decisionEngineService.EmailStatusCallbackGenerator(API_URL,
            Some(msg.createIcdIncidentRegistryRecord.id), msg.userDeliveryRules.userId),
          friendlyDescription = Some(msg.createIcdIncidentRegistryRecord.friendlyDescription),
          measurementUnitSystem = if (msg.unitSystem.isDefined && msg.unitSystem.nonEmpty) msg.unitSystem else None
        ), msg.subscriptionInfo

      ),
      icdAlarmIncidentRegistryId = msg.createIcdIncidentRegistryRecord.id,
      isCsEmail = true
    )
  }
}

object CustomerService {
  val installedAlert = 5001

  def props(producer: ActorRef): Props = Props(classOf[CustomerService], producer)
}
