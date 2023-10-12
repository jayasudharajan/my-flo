package Actors

import MicroService.Lognators.DecisionEngineLognator
import MicroService._
import Models.SubscriptionInfo
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, ActorSystem, Props}
import akka.stream.ActorMaterializer
import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.Enums.Notifications.AlarmNotificationStatuses
import com.flo.Enums.ValveModes
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.Locale.UnitSystemEndpoints
import com.flo.FloApi.v2._
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.flo.Models._
import com.flo.utils.{HttpMetrics, TimestampCompatibilityHelpers}
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.Future
import scala.util.{Failure, Success}

class NotificationLogger(csActor: ActorRef) extends Actor with ActorLogging {

  import context.dispatcher

  implicit val materializer: ActorMaterializer = ActorMaterializer()(context)
  implicit val system: ActorSystem = context.system

  implicit val httpMetrics: HttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )

  private val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()


  //Proxies

  private lazy val proxyAlarmNotificationDeliveryFilters = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)


  private lazy val icdAlarmIncidentRegistryLogEndpoints = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)

  private lazy val deviceInfoEndpoints = new com.flo.FloApi.v2.Analytics.ICDEndpoints(clientCredentialsTokenProvider)
  private lazy val usersGroupAccountRolesEndpoints = new UserAccountGroupRoleEndpoints(clientCredentialsTokenProvider)
  private lazy val accountGroupAlarmNotificationDeliveryRuleEndpoints = new AccountGroupAlarmNotificationDeliveryRuleEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyUserInfo = new UserContactInformationEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionEndpoints = new AccountSubscriptionEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionPlanEndpoints = new SubscriptionPlanEndpoints(clientCredentialsTokenProvider)
  private lazy val unitOfMeasurementEndpoints = new UnitSystemEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_USER_CONTACT_INFORMATION = new UserContactInformationEndpoints(clientCredentialsTokenProvider)


  //service
  private lazy val notificationLoggerHelper = new NotificationLoggerHelper(context, log)
  private lazy val iCDAlarmNotificationDeliveryRuleService = new ICDAlarmNotificationDeliveryRuleService()
  private lazy val accountGroupService = new AccountGroupService()
  private lazy val deviceInfoMicroService = new DeviceInfoMicroService()
  private lazy val frequencyService = new FrequencyService()
  private lazy val lognator = new DecisionEngineLognator()
  private lazy val zendeskService = new ZendeskService()
  private lazy val accountService = new AccountMicroService()
  private lazy val timeService = new TimeService()


  case class IcdAlarmIncidentRegistryLogBasicInfo(
                                                   icd: Option[ICD],
                                                   icdIncidentRegistryRecord: Option[ICDAlarmIncidentRegistry]
                                                 )

  override def preStart = {
    log.info(s"started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"stopped actor ${self.path.name} @ ${self.path.address}")

  }

  def receive = {
    case icdAlarmIncidentMessage: ICDAlarmIncident if icdAlarmIncidentMessage.data.snapshot.systemMode.getOrElse(0) == ValveModes.MANUAL => {
      val incidentTimestamp = Some(TimestampCompatibilityHelpers.toMillisecondsTimestamp(icdAlarmIncidentMessage.ts))
      val systemMode = icdAlarmIncidentMessage.data.snapshot.systemMode.getOrElse(0)
      val alarmId = icdAlarmIncidentMessage.data.alarm.alarmId
      val deviceId = icdAlarmIncidentMessage.deviceId
      val snapshot = icdAlarmIncidentMessage.data.snapshot
      val id = icdAlarmIncidentMessage.id

      val logMsg = lognator.incidentLogMessage(deviceId, icdAlarmIncidentMessage, None)

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
        icdAlarmNotificationDeliveryRules <- notificationLoggerHelper.getIcdAlarmNotificationDeliveryRules(alarmId, ValveModes.HOME)
        userAlarmNotificationDeliveryRules <- notificationLoggerHelper.getUserAlarmNotificationDeliveryRules(icd.get, icdAlarmNotificationDeliveryRules.get, snapshot)

        // GET group ID users' ids
        usersAccountGrouproles <- if (accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId).isEmpty) Future {
          None
        } else usersGroupAccountRolesEndpoints.Get(accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId)) recoverWith {
          case e: Throwable =>
            log.error(e, s"usersAccountGrouproles for did $deviceId exception:")
            throw e
        }
        //GET group delivery rules
        accountgroupDeliveryRules <- if (accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId).isEmpty) Future {
          None
        } else accountGroupAlarmNotificationDeliveryRuleEndpoints.GetByGroupIdAlarmIdSystemMode(accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId), icdAlarmIncidentMessage.data.alarm.alarmId, snapshot.systemMode.get) recoverWith {
          case e: Throwable =>
            log.error(e, s"accountgroupDeliveryRules for did $deviceId exception:")
            throw e
        }
        getAlarmNotificationDeliveryFilters <- proxyAlarmNotificationDeliveryFilters.GetByIcdIdAndByAlarmIdAndBySystemMode(deviceInfoItem.icdId, icdAlarmIncidentMessage.data.alarm.alarmId, snapshot.systemMode.get) recoverWith {
          case e: Throwable =>
            log.error(e, s"alarmNotificationDeliveryFilters log message: $logMsg")
            throw e
        }
        userContactInfo <- proxyUserInfo.GetPlusEmail(deviceInfoItem.ownerUserId.get) recoverWith {
          case e: Throwable =>
            log.error(e, s"userContactInfo log message: $logMsg")
            throw e
        }
        userDetails <- FLO_PROXY_USER_CONTACT_INFORMATION.GetPlusEmail(deviceInfoItem.users.head.userId) recoverWith {
          case e: Throwable =>
            log.error(e, s"Follwing problem happened getting user details: $logMsg")
            throw e
        }
        uniSystem <- unitOfMeasurementEndpoints.Get(userDetails.get.unitSystem.getOrElse("default")) recoverWith {
          case e: Throwable =>
            log.error(e, s"Follwing problem happened getting measurement unit system: $logMsg")
            throw e
        }


        ultimateUserAlarmNotificationDeliveryRules <- Future(iCDAlarmNotificationDeliveryRuleService.UsersAlarmNotificationRuleDeliveryPreferencesGenerator(icdUserIds, icdAlarmNotificationDeliveryRules.get, userAlarmNotificationDeliveryRules.getOrElse(Set()), icd.get, accountgroupDeliveryRules, accountGroupService.getAccountGroupUserIdsByRole(usersAccountGrouproles, UserGroupAccountRoles.LANDLORD), accountGroupService.getAccountGroupUserIdsByRole(usersAccountGrouproles, UserGroupAccountRoles.PROPERTY_MANAGER), usersAccountGrouproles.isDefined && usersAccountGrouproles.nonEmpty))

        icdIncidentRegistryRecord <- notificationLoggerHelper.createIcdIncidentRegistryRecord(icd.get, icdLocation.get, alarmId, icdAlarmNotificationDeliveryRules.get, deviceId, snapshot, ultimateUserAlarmNotificationDeliveryRules.get, incidentTimestamp, id, icdAlarmIncidentMessage, uniSystem.get)

        accountSubscription <- if (accountService.getAccountIdByDeviceId(deviceId, deviceInfo).isEmpty) Future {
          None
        } else subscriptionEndpoints.getByAccountId(accountService.getAccountIdByDeviceId(deviceId, deviceInfo)) recoverWith {
          case e: Throwable =>
            log.error(e, s"accountSubscription log message: $logMsg")
            throw e
        }
        subscriptionPlan <- if (accountService.getPlanIdFromAccountSubscription(accountSubscription).isEmpty) Future {
          None
        } else subscriptionPlanEndpoints.Get(accountService.getPlanIdFromAccountSubscription(accountSubscription)) recoverWith {
          case e: Throwable =>
            log.error(e, s"subscriptionPlan log message: $logMsg")
            throw e
        }

      } yield {
        IcdAlarmIncidentRegistryLogBasicInfo(icd, icdIncidentRegistryRecord)


        icdAlarmIncidentRegistryLogEndpoints.Post(
          Some(
            notificationLoggerHelper.getIcdAlarmIncidentRegistryLog(icdIncidentRegistryRecord.get)
          )
        ).onComplete {
          case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully $logMsg")
          case Failure(e) => log.error(e.toString)
        }
        if (ApplicationSettings.cs.sleepModeAlertSet.contains(alarmId)) {

          ultimateNotificationDeliveryFilter(getAlarmNotificationDeliveryFilters, icd.get, Some(icdIncidentRegistryRecord.get.id), icdAlarmNotificationDeliveryRules.get, snapshot, icdAlarmIncidentMessage.ts) onComplete {
            case Success(alarmNotificationDeliveryFilters) =>


              val ultimateUserAlarmNotificationDeliveryRules = iCDAlarmNotificationDeliveryRuleService.UsersAlarmNotificationRuleDeliveryPreferencesGenerator(icdUserIds, icdAlarmNotificationDeliveryRules.get, Set[UserAlarmNotificationDeliveryRules](), icd.get, None, Set[String](), Set[String](), isManage = false)

              if (frequencyService.isFrequencyAlright(alarmNotificationDeliveryFilters, icdAlarmNotificationDeliveryRules.get.filterSettings.get, isSleepModeCS = true)) {

                updateDeliveryFilter(alarmNotificationDeliveryFilters.get) onComplete {
                  case Success(ok) => log.info(s"filter updated successfully log message : $logMsg ")
                  case Failure(e) => log.error(e, s"filter update failed $logMsg")
                }

                csActor ! zendeskService.generateRegularCSEmailForUserAlert(
                  icdAlarmNotificationDeliveryRules,
                  icd.get,
                  userContactInfo, icdLocation, icdIncidentRegistryRecord.get, icdAlarmIncidentMessage, ultimateUserAlarmNotificationDeliveryRules.get.head, accountSubscription match {
                    case Some(sub) => Some(SubscriptionInfo(sub, subscriptionPlan.get))
                    case _ => None
                  },
                  uniSystem
                )


              }

            case Failure(e) => log.error(s"error ultimateNotificationDeliveryFilter log message $logMsg ", e)
          }
        }

      }
    }
  }


  /**
    * This method returns a newly created ICDAlarmNotificationDeliveryFilter if the ICD doesn't have a record for that Alarm id and system mode combination. It returns the existing one otherwise.
    **/
  private def ultimateNotificationDeliveryFilter(filters: Option[AlarmNotificationDeliveryFilters], icd: ICD, incidentId: Option[String], deliveryRules: ICDAlarmNotificationDeliveryRules, snapshot: ICDAlarmIncidentDataSnapshot, incidentTs: Long): Future[Option[AlarmNotificationDeliveryFilters]] = {
    if (filters.isDefined && filters.get.icdId.isDefined) {
      Future {
        filters
      }
    }
    else {
      proxyAlarmNotificationDeliveryFilters.Post(
        Some(
          AlarmNotificationDeliveryFilters(
            icdId = icd.id,
            alarmId = Some(deliveryRules.alarmId),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            expiresAt = Some(DateTime.now(DateTimeZone.UTC).plusYears(100).toDateTimeISO.toString()),
            lastDecisionUserId = None,
            status = Some(AlarmNotificationStatuses.RESOLVED),
            systemMode = snapshot.systemMode,
            lastIcdAlarmIncidentRegistryId = incidentId,
            incidentTime = Some(timeService.epochTimeStampToStringISODate(Some(incidentTs))),
            severity = Some(deliveryRules.severity)
          )
        )
      )
    }

  }

  private def updateDeliveryFilter(filter: AlarmNotificationDeliveryFilters): Future[Option[AlarmNotificationDeliveryFilters]] = {
    proxyAlarmNotificationDeliveryFilters.Put(
      Some(
        filter.copy(updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()))

      ))

  }


}

object NotificationLogger {
  def props(
             cs: ActorRef
           ): Props = Props(classOf[NotificationLogger], cs)
}