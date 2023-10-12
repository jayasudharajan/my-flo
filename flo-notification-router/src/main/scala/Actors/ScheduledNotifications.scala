package Actors

import MicroService._
import Models.Mediums.PreProcessingMessage
import Models.SubscriptionInfo
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, ActorSystem, Props}
import akka.stream.ActorMaterializer
import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.Enums.Notifications.AlarmNotificationStatuses
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsTokenProvider, FloTokenProviders}
import com.flo.FloApi.v2.Locale.UnitSystemEndpoints
import com.flo.FloApi.v2._
import com.flo.Models.Analytics.{DeviceInfo, DeviceInfoItem}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.flo.Models._
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.util.{Failure, Success}

/**
  * Created by Francisco on 5/21/2017.
  */
/**
  * Sypsnosis
  * 1) get ICDAlarmIncident record
  * 2) get ICDAlarmNotificationDeliveryFilter for that alarm
  * 3) See if alert has been resolved, if it has, do not send Notification, if it hasn't send notification
  **/


class ScheduledNotifications(preDelivery: ActorRef) extends Actor with ActorLogging {

  implicit val materializer: ActorMaterializer = ActorMaterializer()(context)
  implicit val system: ActorSystem = context.system

  implicit val httpMetrics: HttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider: ClientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()


  private lazy val proxyIcdAlarmDeliveryRules = new ICDAlarmNotificationDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyUserAlarmNotificationDeliveryRules = new UserAlarmDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyIcdAlarmNotificationDeliveryFilters = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)
  private lazy val proxyIcdAlarmRegistryIncident = new ICDAlarmIncidentRegistryEndpoints(clientCredentialsTokenProvider)
  private lazy val unitOfMeasurementEndpoints = new UnitSystemEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_USER_CONTACT_INFORMATION = new UserContactInformationEndpoints(clientCredentialsTokenProvider)


  private lazy val deviceInfoEndpoints = new com.flo.FloApi.v2.Analytics.ICDEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionEndpoints = new AccountSubscriptionEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionPlanEndpoints = new SubscriptionPlanEndpoints(clientCredentialsTokenProvider)
  private lazy val usersGroupAccountRolesEndpoints = new UserAccountGroupRoleEndpoints(clientCredentialsTokenProvider)
  private lazy val accountGroupAlarmNotificationDeliveryRuleEndpoints = new AccountGroupAlarmNotificationDeliveryRuleEndpoints(clientCredentialsTokenProvider)


  //services
  private lazy val accountService = new AccountMicroService()
  private lazy val accountGroupService = new AccountGroupService()
  private lazy val validationService = new ValidationService()
  private lazy val scheduledNotificationsService = new ScheduledNotificationService()
  private lazy val alertService = new AlertService(context)
  private lazy val timeService = new TimeService()
  private lazy val iCDAlarmNotificationDeliveryRuleService = new ICDAlarmNotificationDeliveryRuleService()
  private lazy val deviceInfoMicroService = new DeviceInfoMicroService()
  private lazy val frequencyService = new FrequencyService()
  private lazy val snapshotService = new SnapShotMicroService()

  def receive = {

    case scheduledAlarmMessage: ICDAlarmIncident =>
      validationService.scheduledNotificationMessageValidation(scheduledAlarmMessage)
      val deviceId = scheduledAlarmMessage.deviceId
      val alarm = scheduledAlarmMessage.data.alarm
      val snapshot = scheduledAlarmMessage.data.snapshot
      val incidentId = scheduledAlarmMessage.scheduledNotificationInfo.get.incidentRegistryId

      lazy val logIdStr = s"device_id $deviceId incident id: $incidentId"

      /**
        * First check the status of the incident, make sure the incident record exists and that the filter exists and it is not resolved.
        **/
      for {
        incidentRecord <- proxyIcdAlarmRegistryIncident.Get(incidentId) recoverWith {
          case e: Throwable =>
            log.error(s"proxyIcdAlarmRegistryIncident.Get for $logIdStr error: ${e.toString}")
            throw e
        }
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
        alarmNotificationDeliveryFilter <- proxyIcdAlarmNotificationDeliveryFilters.GetByIcdIdAndByAlarmIdAndBySystemMode(icdId = icd.get.id.get, alarmId = alarm.alarmId, systemMode = snapshot.systemMode.get) recoverWith {
          case e: Throwable =>
            log.error(s"proxyIcdAlarmNotificationDeliveryFilters.GetByIcdIdAndByAlarmIdAndBySystemMode $logIdStr error: ${e.toString}")
            throw e
        }

      } yield {
        //making sure icd and records are still valid
        if (incidentRecord.isEmpty)
          throw new IllegalStateException(s" proxyIcdAlarmRegistryIncident.Get incident record does not exist $logIdStr")
        if (icd.isEmpty)
          throw new IllegalStateException(s"proxyIcd.GetByDeviceId icd doesn't exist $logIdStr")

        //Determine the status of the filter
        scheduledNotificationsService.processAlarmNotificationDeliveryFilter(alarmNotificationDeliveryFilter) match {
          case Success(filterStatus) =>
            filterStatus match {
              case AlarmNotificationStatuses.RESOLVED =>
                log.info(s"scheduled alert has been already resolved. $logIdStr")
              case AlarmNotificationStatuses.UNRESOLVED =>

                processUnresolvedAlarmNotificationFilter(alarmNotificationDeliveryFilter.get, icd.get, incidentRecord.get, scheduledAlarmMessage, logIdStr, deviceInfo, deviceInfoItem)
              case AlarmNotificationStatuses.IGNORED =>
              //TODO: handle ignored cases here
            }

          case Failure(e) =>
            log.error(s"scheduledNotificationsService.processAlarmNotificationDeliveryFilter $logIdStr error: ${e.toString}")
        }

      }
  }

  def processUnresolvedAlarmNotificationFilter(filter: AlarmNotificationDeliveryFilters, icd: ICD, incident: ICDAlarmIncidentRegistry, scheduledAlarmMessage: ICDAlarmIncident, logText: String, deviceInfo: Option[DeviceInfo], deviceInfoItem: DeviceInfoItem): Unit = {
    val alarm = scheduledAlarmMessage.data.alarm
    val snapshot = scheduledAlarmMessage.data.snapshot
    val deviceId = scheduledAlarmMessage.deviceId

    // get users that need to be inform about the icd's alarm anf their delivery preferences.
    for {
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

      userAlarmNotificationDeliveryRules <- proxyUserAlarmNotificationDeliveryRules.GetByLocationIdAndAlarmDeliveryRulesIdAndSystemMode(icd.locationId.get, alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(s"proxyUserAlarmNotificationDeliveryRules.GetByLocationIdAndAlarmDeliveryRulesIdAndSystemMode $logText error: ${e.toString}")
          throw e
      }
      icdAlarmNotificationDeliveryRules <- proxyIcdAlarmDeliveryRules.GetByAlarmIdAndBySystemMode(alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(s"proxyIcdAlarmDeliveryRules.GetByAlarmIdAndBySystemMode $logText error: ${e.toString}")
          throw e
      }

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
      } else accountGroupAlarmNotificationDeliveryRuleEndpoints.GetByGroupIdAlarmIdSystemMode(accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId), alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(e, s"accountgroupDeliveryRules for did $deviceId exception:")
          throw e
      }
      accountSubscription <- if (accountService.getAccountIdByDeviceId(deviceId, deviceInfo).isEmpty) Future {
        None
      } else subscriptionEndpoints.getByAccountId(accountService.getAccountIdByDeviceId(deviceId, deviceInfo)) recoverWith {
        case e: Throwable =>
          log.error(e, s"accountSubscription log message: $logText")
          throw e
      }
      subscriptionPlan <- if (accountService.getPlanIdFromAccountSubscription(accountSubscription).isEmpty) Future {
        None
      } else subscriptionPlanEndpoints.Get(accountService.getPlanIdFromAccountSubscription(accountSubscription)) recoverWith {
        case e: Throwable =>
          log.error(e, s"subscriptionPlan log message: $logText")
          throw e
      }


    } yield {
      val subscriptioninfo = accountSubscription match {
        case Some(sub) => Some(SubscriptionInfo(sub, subscriptionPlan.get))
        case _ => None
      }

      val isManaged = accountGroupService.isPropertyManaged(usersAccountGrouproles)
      val landlordsUserId = accountGroupService.getAccountGroupUserIdsByRole(usersAccountGrouproles, UserGroupAccountRoles.LANDLORD)
      val propertyManagerIds = accountGroupService.getAccountGroupUserIdsByRole(usersAccountGrouproles, UserGroupAccountRoles.PROPERTY_MANAGER)

      val ultimateAlarmNotificationDeliveryRules = iCDAlarmNotificationDeliveryRuleService.UsersAlarmNotificationRuleDeliveryPreferencesGenerator(icdUserIds, icdAlarmNotificationDeliveryRules.get, userAlarmNotificationDeliveryRules.getOrElse(Set[UserAlarmNotificationDeliveryRules]()), icd, accountgroupDeliveryRules, landlordsUserId, propertyManagerIds, isManaged)

      ultimateAlarmNotificationDeliveryRules.get.foreach(userRules => {

        val userAlarmFilterSettings = iCDAlarmNotificationDeliveryRuleService.getUserAlarmFilterSettings(userRules.filterSettings, icdAlarmNotificationDeliveryRules.get.filterSettings, alarm.alarmId, snapshot.systemMode.get)

        //Make sure Delivery frequency is adequate
        val isFrequencyAlright = frequencyService.isFrequencyAlright(Some(filter), userAlarmFilterSettings, isScheduled = true)

        if (userAlarmFilterSettings.exempted) {
          log.info(s"Alarm with internal id  ${icdAlarmNotificationDeliveryRules.get.internalId} was exempted from filtering  for icd ID : ${filter.icdId.getOrElse("N/A")} info: $logText")
        }

        ultimateNotificationDeliveryService(Some(filter), icd, Some(incident.id), icdAlarmNotificationDeliveryRules.get, snapshot, Some(scheduledAlarmMessage.ts)) onComplete {
          case Success(ultimateDeliveryFilter) =>

            val tooMuchTimeElapsed = timeService.tooMuchTimeElapsedSinceIncidentValidator(scheduledAlarmMessage.ts, userAlarmFilterSettings.maxMinutesElapsedSinceIncidentTime, scheduledAlarmMessage.scheduledNotificationInfo)

            val closedValveFiltered = snapshotService.isValveClosed(snapshot.valveSwitch1, snapshot.valveSwitch2) && !userAlarmFilterSettings.sendWhenValveIsClosed

            if (isFrequencyAlright && !closedValveFiltered && !tooMuchTimeElapsed && scheduledAlarmMessage.scheduledNotificationInfo.get.userId == userRules.userId) {
              for {
                userDetails <- FLO_PROXY_USER_CONTACT_INFORMATION.GetPlusEmail(scheduledAlarmMessage.scheduledNotificationInfo.get.userId) recoverWith {
                  case e: Throwable =>
                    log.error(e, s"Follwing problem happened getting user details:")
                    throw e
                }
                unitSystem <- unitOfMeasurementEndpoints.Get(userDetails.get.unitSystem.getOrElse("default")) recoverWith {
                  case e: Throwable =>
                    log.error(e, s"Following problem happened getting measurement unit system:")
                    throw e
                }
              } yield {
                preDelivery ! PreProcessingMessage(
                  ultimateAlarmNotificationDeliveryFilters = ultimateDeliveryFilter.get,
                  createIcdIncidentRegistryRecord = Some(incident),
                  icdAlarmIncidentMessage = scheduledAlarmMessage,
                  icdLocation.get,
                  snapshot,
                  icdAlarmNotificationDeliveryRules,
                  Some(icd),
                  userRules,
                  alertService.hasUserMutedTheAlarm(ultimateAlarmNotificationDeliveryRules.get),
                  isUserLandLord = (isManaged && landlordsUserId.contains(userRules.userId)) || propertyManagerIds.contains(userRules.userId),
                  isUserTenant = isManaged && !landlordsUserId.contains(userRules.userId),
                  subscriptioninfo,
                  unitSystem.get
                )

              }


            }
          case Failure(e) =>
            log.error(s"ultimateNotificationDeliveryService $logText error: ${e.toString}")
            throw e
        }


      })


    }


  }


  /**
    * This method returns a newly created ICDAlarmNotificationDeliveryFilter if the ICD doesn't have a record for that Alarm id and system mode combination. It returns the existing one otherwise.
    **/
  ///TODO: Metric timer
  private def ultimateNotificationDeliveryService(filters: Option[AlarmNotificationDeliveryFilters], icd: ICD, incidentId: Option[String], deliveryRules: ICDAlarmNotificationDeliveryRules, snapshot: ICDAlarmIncidentDataSnapshot, incidentTs: Option[Long]): Future[Option[AlarmNotificationDeliveryFilters]] = {
    if (filters.isDefined && filters.get.icdId.isDefined) {
      Future {
        filters
      }
    }
    else {
      proxyIcdAlarmNotificationDeliveryFilters.Post(
        Some(
          AlarmNotificationDeliveryFilters(
            icdId = icd.id,
            alarmId = Some(deliveryRules.alarmId),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            expiresAt = Some(DateTime.now(DateTimeZone.UTC).plusYears(100).toDateTimeISO.toString()),
            lastDecisionUserId = None,
            status = if (alertService.isAlarmAutoLog(deliveryRules.internalId) || alertService.isAlarmInfoLevel(deliveryRules.severity)) Some(AlarmNotificationStatuses.RESOLVED) else Some(AlarmNotificationStatuses.UNRESOLVED),
            systemMode = snapshot.systemMode,
            lastIcdAlarmIncidentRegistryId = incidentId,
            incidentTime = Some(timeService.epochTimeStampToStringISODate(incidentTs)),
            severity = Some(deliveryRules.severity)
          )
        )
      )
    }

  }


}

object ScheduledNotifications {
  def props(
             preDelivery: ActorRef
           ): Props = Props(classOf[ScheduledNotifications], preDelivery)
}