package Actors


import MicroService.Lognators.DecisionEngineLognator
import MicroService._
import Models.Actors.RudimentaryIncidentInfo
import Models.Mediums.PreProcessingMessage
import Models._
import Nators.ICDAlarmIncidentRegistryGenerators
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, OneForOneStrategy, Props, SupervisorStrategy}
import akka.stream._
import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.Enums.Notifications._
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.Locale.UnitSystemEndpoints
import com.flo.FloApi.v2._
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ICDAlarmIncidentDataSnapshot, UserActivityEvent}
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Logs.ICDAlarmIncidentRegistryLog
import com.flo.Models.Users._
import com.flo.Models._
import com.flo.utils.HttpMetrics
import com.redis.RedisClient
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._
import scala.concurrent.{Await, Future}
import scala.util.{Failure, Success}


/**
  * Created by Francisco on 5/31/2016.
  */
class DecisionEngine(preDelivery: ActorRef) extends Actor with ActorLogging {

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  private lazy val API_URL = ApplicationSettings.flo.api.url.getOrElse(throw new Exception("FLO_API_URL was not found in config nor env vars"))

  private lazy val FLO_PROXY_ICD_ALARM_NOTIFICATION_DELIVERY_RULES = new ICDAlarmNotificationDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_USER_ALARM_NOTIFICATION_DELIVERY_RULES = new UserAlarmDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_USER_CONTACT_INFORMATION = new UserContactInformationEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY = new ICDAlarmIncidentRegistryEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY_LOG = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)
  private lazy val deviceInfoEndpoint = new com.flo.FloApi.v2.Analytics.ICDEndpoints(clientCredentialsTokenProvider)
  private lazy val usersGroupAccountRolesEndpoints = new
      UserAccountGroupRoleEndpoints(clientCredentialsTokenProvider)
  private lazy val accountGroupAlarmNotificationDeliveryRuleEndpoints = new AccountGroupAlarmNotificationDeliveryRuleEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionEndpoints = new AccountSubscriptionEndpoints(clientCredentialsTokenProvider)
  private lazy val subscriptionPlanEndpoints = new SubscriptionPlanEndpoints(clientCredentialsTokenProvider)
  private lazy val unitOfMeasurementEndpoints = new UnitSystemEndpoints(clientCredentialsTokenProvider)

  //services
  private lazy val VALIDATION_SERVICE = new ValidationService()
  private lazy val alertService = new AlertService(context)
  private lazy val accountGroupService = new AccountGroupService()
  private lazy val accountService = new AccountMicroService()
  private lazy val lognator = new DecisionEngineLognator()
  private lazy val timeService = new TimeService()
  private lazy val iCDAlarmNotificationDeliveryRuleService = new
      ICDAlarmNotificationDeliveryRuleService()
  private lazy val deviceInfoMicroService = new DeviceInfoMicroService()
  private lazy val frequencyService = new FrequencyService()
  private lazy val snapshotService = new SnapShotMicroService()

  private val redisClient = new RedisClient(ApplicationSettings.redis.host, ApplicationSettings.redis.port)
  private val alarmRuleEngine = new AlarmRuleEngine(redisClient)

  //nators

  override def preStart = {
    log.info(s"DecisionEngine started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"DecisionEngine stopped actor ${self.path.name} @ ${self.path.address}")

  }

  override def supervisorStrategy = OneForOneStrategy() {
    case (ex: Throwable) => log.error(ex, "DecisionEngineSuperV")
      SupervisorStrategy.Restart
  }


  def receive = {

    case icdAlarmIncidentMessage: ICDAlarmIncident =>

      try {
        VALIDATION_SERVICE.iCDAlarmIncidentMessageValidation(icdAlarmIncidentMessage)

        val deviceId = icdAlarmIncidentMessage.deviceId

        val snapshot = icdAlarmIncidentMessage.data.snapshot

        getRudimentaryInfo(icdAlarmIncidentMessage, deviceId, snapshot) onComplete {
          case Failure(ex: Throwable) => log.error(ex, s"The following error occured getting rudimentary data for incident log message: ${lognator.incidentLogMessage(deviceId, icdAlarmIncidentMessage, None)}")
          case Success(rIinfo) =>
            val icdIncidentRegistryGenerator = new ICDAlarmIncidentRegistryGenerators(context, rIinfo.unitSystem)

            val logMessage = lognator.incidentLogMessage(deviceId, icdAlarmIncidentMessage, None)
            if (rIinfo.deliveryRules.isDeleted) {
              log.warning(s"Trying  to send alarm id: ${rIinfo.deliveryRules.alarmId} which has been erased log message: $logMessage")
              throw new Exception("Alarm does not exist")
            }
            lazy val decisionService = new DecisionEngineService(rIinfo.unitSystem)

            log.info(s"gathering account management info if any log message: $logMessage")
            val isManaged = accountGroupService.isPropertyManaged(rIinfo.usersAccountGroupRoles)
            val landlordsUserId = accountGroupService.getAccountGroupUserIdsByRole(rIinfo.usersAccountGroupRoles, UserGroupAccountRoles.LANDLORD)
            val propertyManagerIds = accountGroupService.getAccountGroupUserIdsByRole(rIinfo.usersAccountGroupRoles, UserGroupAccountRoles.PROPERTY_MANAGER)

            val ultimateUserAlarmNotificationDeliveryRules = iCDAlarmNotificationDeliveryRuleService.UsersAlarmNotificationRuleDeliveryPreferencesGenerator(rIinfo.icdUsersIds.get, rIinfo.deliveryRules, rIinfo.userAlarmNotificationDeliveryRules.getOrElse(Set[UserAlarmNotificationDeliveryRules]()), rIinfo.icd.get, rIinfo.accountGroupDeliveryRules, landlordsUserId, propertyManagerIds, isManaged)

            val incidentId = icdAlarmIncidentMessage.id
            val fCreateIcdIncidentRegistryRecord = FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY.Post(Some(icdIncidentRegistryGenerator.incidentPostGenerator(
              rIinfo.icdLocation.get,
              rIinfo.icd.get,
              icdAlarmIncidentMessage,
              rIinfo.deliveryRules,
              ultimateUserAlarmNotificationDeliveryRules.get,
              incidentId,
              getUserNameForUserActivityEvent(icdAlarmIncidentMessage.userActivityEvent)
            )))

            ultimateUserAlarmNotificationDeliveryRules.get.foreach(userRules => {
              val userAlarmFilterSettings: ICDAlarmNotificationFilterSettings = userRules.filterSettings match {
                case Some(f) => f

                case _ =>
                  rIinfo.deliveryRules.filterSettings.getOrElse(throw new Exception(s"filter settings not found for alarm internal id ${rIinfo.deliveryRules.internalId} log message: $logMessage"))
              }
              val frequencyIsAlright = frequencyService.isFrequencyAlright(rIinfo.alarmNotificationDeliveryFilters, userAlarmFilterSettings)

              if (userAlarmFilterSettings.exempted) {
                log.info(s"Alarm with internal id  ${rIinfo.deliveryRules.internalId} was exempted from filtering log message: $logMessage")
              }

              for {
                createIcdIncidentRegistryRecord <- fCreateIcdIncidentRegistryRecord recoverWith {
                  case e: Throwable =>
                    log.error(s"fCreateIcdIncidentRegistryRecord ${e.toString}")
                    throw e
                }
                ultimateAlarmNotificationDeliveryFilters <- ultimateNotificationDeliveryService(rIinfo.alarmNotificationDeliveryFilters, rIinfo.icd.get, Some(createIcdIncidentRegistryRecord.get.id), rIinfo.deliveryRules, snapshot, icdAlarmIncidentMessage.ts) recoverWith {
                  case e: Throwable =>
                    log.error(s"fUltimateAlarmNoticatificationDeliveryFilters ${e.toString}")
                    throw e
                }
              } yield {

                val logMsg = lognator.incidentLogMessage(deviceId, icdAlarmIncidentMessage, createIcdIncidentRegistryRecord)

                // ########  COLLATERAL UPDATES
                val collateralUpdates = context.actorOf(Props[AlertCollateralUpdates])

                collateralUpdates ! AlertCollateralUpdatesMessage(
                  rIinfo.deliveryRules.internalId,
                  rIinfo.icd.get.id.get,
                  Some(createIcdIncidentRegistryRecord.get.id)
                )

                //COLLATERAL UPDATES

                val tooMuchTimeHasElapsed = timeService.tooMuchTimeElapsedSinceIncidentValidator(icdAlarmIncidentMessage.ts, userAlarmFilterSettings.maxMinutesElapsedSinceIncidentTime)
                val closedValveFiltered: Boolean = snapshotService.isValveClosed(snapshot.valveSwitch1, snapshot.valveSwitch2) && !userAlarmFilterSettings.sendWhenValveIsClosed

                val shouldAlarmBeSent = alarmRuleEngine.shouldBeSent(icdAlarmIncidentMessage)

                if (shouldAlarmBeSent && frequencyIsAlright && !closedValveFiltered && !tooMuchTimeHasElapsed) {
                  //Property Management

                  preDelivery ! PreProcessingMessage(
                    ultimateAlarmNotificationDeliveryFilters.get,
                    createIcdIncidentRegistryRecord,
                    icdAlarmIncidentMessage,
                    rIinfo.icdLocation.get,
                    snapshot,
                    Some(rIinfo.deliveryRules),
                    rIinfo.icd,
                    userRules,
                    alertService.hasUserMutedTheAlarm(ultimateUserAlarmNotificationDeliveryRules.get),
                    (isManaged && landlordsUserId.contains(userRules.userId)) || propertyManagerIds.contains(userRules.userId),
                    isManaged && !landlordsUserId.contains(userRules.userId),
                    rIinfo.subscriptionInfo,
                    rIinfo.unitSystem
                  )
                }
                else {
                  filteredAlarmPostProcessing(
                    shouldAlarmBeSent,
                    frequencyIsAlright,
                    closedValveFiltered,
                    tooMuchTimeHasElapsed,
                    icdAlarmIncidentMessage,
                    ultimateAlarmNotificationDeliveryFilters.get.lastDecisionUserId,
                    Some(createIcdIncidentRegistryRecord.get.id),
                    rIinfo.icd.get,
                    rIinfo.deliveryRules
                  )

                }
              }

            })
        }
      }
      catch {
        case e: Throwable =>
          log.error(e.toString)
      }
  }


  /**
    * This method returns a newly created ICDAlarmNotificationDeliveryFilter if the ICD doesn't have a record for that Alarm id and system mode combination. It returns the existing one otherwise.
    **/
  ///TODO: Metric timer
  def ultimateNotificationDeliveryService(filters: Option[AlarmNotificationDeliveryFilters], icd: ICD, incidentId: Option[String], deliveryRules: ICDAlarmNotificationDeliveryRules, snapshot: ICDAlarmIncidentDataSnapshot, incidentTs: Long): Future[Option[AlarmNotificationDeliveryFilters]] = {
    if (filters.isDefined && filters.get.icdId.isDefined) {
      Future {
        filters
      }
    }
    else {
      FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.Post(
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
            incidentTime = Some(timeService.epochTimeStampToStringISODate(Some(incidentTs))),
            severity = Some(deliveryRules.severity)
          )
        )
      )
    }

  }


  /** This method will log the reason why the notification wasn't delivered to the user
    * */
  ///TODO: Metric timer
  private def filteredAlarmPostProcessing(shouldSmallDripAlarmBeSent: Boolean, frequencyIsAlright: Boolean, closedValveFiltered: Boolean, tooMuchTimeHasElapsed: Boolean, icdAlarmIncidentMessage: ICDAlarmIncident, lastDecisionUserId: Option[String], createIcdIncidentRegistryRecordId: Option[String], iCD: ICD, icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules): Unit = {
    if (!frequencyIsAlright) {
      log.info(s"Frequency was not alright, you need to wait a certain time interval to send another notification to user  device id : ${icdAlarmIncidentMessage.deviceId} alarm id : ${icdAlarmIncidentMessage.data.alarm.alarmId} system mode : ${icdAlarmIncidentMessage.data.snapshot.systemMode.getOrElse("N/A")}  ")
    }

    if (!shouldSmallDripAlarmBeSent) {
      FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY_LOG.Post(Some(
        ICDAlarmIncidentRegistryLog(
          id = Some(java.util.UUID.randomUUID().toString),
          createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdAlarmIncidentRegistryId = createIcdIncidentRegistryRecordId,
          userId = lastDecisionUserId,
          deliveryMedium = Some(DeliveryMediums.FILTERED),
          status = Some(ICDAlarmIncidentRegistryLogStatus.SMALL_DRIP_FILTERED),
          receiptId = Some(java.util.UUID.randomUUID().toString)
        )
      )).onComplete {
        case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully as Filtered icd: ${iCD.id.getOrElse(s"N/A")} alarm ID: ${icdAlarmNotificationDeliveryRules.alarmId} system mode: ${icdAlarmNotificationDeliveryRules.systemMode} SMALL_DRIP_FILTERED")
        case Failure(e) => log.error(e.toString)
      }

      FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.Post(
        Some(
          AlarmNotificationDeliveryFilters(
            icdId = iCD.id,
            alarmId = Some(icdAlarmIncidentMessage.data.alarm.alarmId),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            expiresAt = Some(timeService.epochTimeStampToStringISODate(Some(icdAlarmIncidentMessage.ts))),
            lastDecisionUserId = None,
            status = Some(AlarmNotificationStatuses.IGNORED),
            systemMode = icdAlarmIncidentMessage.data.snapshot.systemMode,
            lastIcdAlarmIncidentRegistryId = createIcdIncidentRegistryRecordId,
            incidentTime = Some(timeService.epochTimeStampToStringISODate(Some(icdAlarmIncidentMessage.ts))),
            severity = Some(icdAlarmNotificationDeliveryRules.severity)
          )
        )
      )
    }

    if (closedValveFiltered) {
      FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY_LOG.Post(Some(
        ICDAlarmIncidentRegistryLog(
          id = Some(java.util.UUID.randomUUID().toString),
          createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdAlarmIncidentRegistryId = createIcdIncidentRegistryRecordId,
          userId = lastDecisionUserId,
          deliveryMedium = Some(DeliveryMediums.FILTERED),
          status = Some(ICDAlarmIncidentRegistryLogStatus.CLOSEDVALVEFILTERED),
          receiptId = Some(java.util.UUID.randomUUID().toString)
        )
      )).onComplete {
        case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully as Filtered icd: ${iCD.id.getOrElse(s"N/A")} alarm ID: ${icdAlarmNotificationDeliveryRules.alarmId} system mode: ${icdAlarmNotificationDeliveryRules.systemMode} CLOSEDVALVEFILTERED")
        case Failure(e) => log.error(e.toString)
      }
    }
    if (tooMuchTimeHasElapsed) {
      FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY_LOG.Post(Some(
        ICDAlarmIncidentRegistryLog(
          id = Some(java.util.UUID.randomUUID().toString),
          createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdAlarmIncidentRegistryId = createIcdIncidentRegistryRecordId,
          userId = lastDecisionUserId,
          deliveryMedium = Some(DeliveryMediums.FILTERED),
          status = Some(ICDAlarmIncidentRegistryLogStatus.TIMEELAPSEDSINCEINCIDENTISTOOMUCH),
          receiptId = Some(java.util.UUID.randomUUID().toString)
        )
      )).onComplete {
        case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully as Filtered icd: ${iCD.id.getOrElse(s"N/A")} alarm ID: ${icdAlarmNotificationDeliveryRules.alarmId} system mode: ${icdAlarmNotificationDeliveryRules.systemMode} TIMEELAPSEDSINCEINCIDENTISTOOMUCH")
        case Failure(e) => log.error(e.toString)
      }

    }
  }

  private def getUserNameForUserActivityEvent(userActivityEvent: Option[UserActivityEvent]): String = userActivityEvent match {
    case None =>
      "N/A"
    case Some(userActivity) =>

      Await.result(FLO_PROXY_USER_CONTACT_INFORMATION.GetPlusEmail(userActivity.userId), 10 seconds) match {
        case None =>
          "N/A"
        case Some(info) =>
          s"${info.firstName.getOrElse("")} ${nameToInitial(info.lastName, addPeriod = true)}"
      }
  }

  private def nameToInitial(name: Option[String], addPeriod: Boolean = false): String = name match {
    case None =>
      ""
    case Some(userName) if userName.isEmpty =>
      ""
    case Some(n) =>
      s"${n.subSequence(0, 1).toString.toUpperCase()}${if (addPeriod) "."} "
  }

  private def getRudimentaryInfo(icdAlarmIncidentMessage: ICDAlarmIncident, deviceId: String, snapshot: ICDAlarmIncidentDataSnapshot): Future[RudimentaryIncidentInfo] = {
    val logMsg = lognator.incidentLogMessage(deviceId, icdAlarmIncidentMessage, None)
    log.info(s"starting to gather rudimentary info for log message: $logMsg")
    for {
      deviceInfo <- deviceInfoEndpoint.getDeviceInfo(deviceId) recoverWith {
        case e: Throwable =>
          log.error(e, s"deviceInfo log message: $logMsg")
          throw e
      }
      deviceInfoItem <- Future {
        deviceInfoMicroService.getDeviceInfoByDeviceId(deviceInfo, deviceId)
      }

      //Get the Alarm Notification Delivery Rule
      icdAlarmNotificationDeliveryRules <- FLO_PROXY_ICD_ALARM_NOTIFICATION_DELIVERY_RULES.GetByAlarmIdAndBySystemMode(icdAlarmIncidentMessage.data.alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(e, s"icdAlarmNotificationDeliveryRules log message: $logMsg")
          throw e
      }
      //Get Users Alarm Notification Delivery Rules
      userAlarmNotificationDeliveryRules <- FLO_PROXY_USER_ALARM_NOTIFICATION_DELIVERY_RULES.GetByLocationIdAndAlarmDeliveryRulesIdAndSystemMode(
        deviceInfoMicroService.getLocationId(deviceInfoItem),
        icdAlarmNotificationDeliveryRules.get.alarmId,
        snapshot.systemMode.getOrElse(throw new IllegalArgumentException(s"systemMode was not found in icd object received from ICDAlarmIncident log message: $logMsg"))) recoverWith {
        case e: Throwable =>
          log.error(e, s"userAlarmNotificationDeliveryRules log message: $logMsg")
          throw e
      }
      alarmNotificationDeliveryFilters <- FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.GetByIcdIdAndByAlarmIdAndBySystemMode(deviceInfoItem.icdId, icdAlarmIncidentMessage.data.alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(e, s"alarmNotificationDeliveryFilters log message: $logMsg")
          throw e
      }

      // GET group ID users' ids
      usersAccountGrouproles <- if (accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId).isEmpty) Future {
        None
      } else usersGroupAccountRolesEndpoints.Get(accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId)) recoverWith {
        case e: Throwable =>
          log.error(e, s"usersAccountGrouproles log message: $logMsg")
          throw e
      }
      //GET group delivery rules
      accountgroupDeliveryRules <- if (accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId).isEmpty) Future {
        None
      } else accountGroupAlarmNotificationDeliveryRuleEndpoints.GetByGroupIdAlarmIdSystemMode(accountGroupService.getGroupIdFromDeviceInfo(deviceInfo, deviceId), icdAlarmIncidentMessage.data.alarm.alarmId, snapshot.systemMode.get) recoverWith {
        case e: Throwable =>
          log.error(e, s"accountgroupDeliveryRules log message: $logMsg")
          throw e
      }

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
      userDetails <- FLO_PROXY_USER_CONTACT_INFORMATION.GetPlusEmail(deviceInfoItem.users.head.userId) recoverWith {
        case e: Throwable =>
          log.error(e, s"Following problem happened getting user details: $logMsg")
          throw e
      }
      uniSystem <- unitOfMeasurementEndpoints.Get(userDetails.get.unitSystem.getOrElse("default")) recoverWith {
        case e: Throwable =>
          log.error(e, s"Following problem happened getting measurement unit system: $logMsg")
          throw e
      }

    } yield {

      log.info(s"rudimentary info gathered for log message: $logMsg")

      log.info(s"getting icd from deviceInfo for log message: $logMsg")
      val iCD = deviceInfoMicroService.getICD(deviceInfoItem, snapshot)

      log.info(s"getting icdUserIds from deviceInfo for log message: $logMsg")
      val icdUserIds = Some(deviceInfoItem.users map (_.userId))

      log.info(s"getting icdLocation from deviceInfo for log message: $logMsg")
      val icdLocation = deviceInfoMicroService.getLocationFromGeoLocation(deviceInfoItem)

      VALIDATION_SERVICE.validateRudimentaryInfo(iCD, icdUserIds, icdLocation) match {
        case Right(nice) =>

          log.info(s"rudimentary info passed validation for log message: $logMsg results passed: ${nice.toString}")

          new RudimentaryIncidentInfo(
            icdAlarmNotificationDeliveryRules.get,
            iCD,
            icdUserIds,
            userAlarmNotificationDeliveryRules,
            alarmNotificationDeliveryFilters,
            icdLocation,
            deviceInfo,
            usersAccountGrouproles,
            accountgroupDeliveryRules,
            accountSubscription match {
              case Some(sub) => Some(SubscriptionInfo(sub, subscriptionPlan.get))
              case _ => None
            },
            uniSystem.get
          )
        case Left(ex: Throwable) => throw new IllegalArgumentException(s"failed rudimentary info validation log message: $logMsg", ex)
      }

    }

  }

}

object DecisionEngine {
  def props(
             preDelivery: ActorRef
           ): Props = Props(classOf[DecisionEngine], preDelivery)
}
