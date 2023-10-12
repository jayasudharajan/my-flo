package MicroService

import Utils.ApplicationSettings
import akka.actor.ActorContext
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.{AlarmNotificationStatuses, AlarmSeverity}

import com.flo.Enums.ValveModes
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.AlarmNotificationDeliveryFiltersEndpoints
import com.flo.Models.AlarmNotificationDeliveryFilters
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.flo.utils.HttpMetrics
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.collection.parallel.ParSet
import scala.util.{Failure, Success}

/**
  * Created by Francisco on 6/16/2017.
  */
class AlertService(context: ActorContext) extends LazyLogging {

  import context.dispatcher

  implicit val mt = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  private lazy val mutedAlarmsInternalIds = Set(1064, 1065, 1066, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1082, 1083, 1085, 1086, 1088, 1089, 1091, 1092, 1094, 1095, 1097, 1098, 1100, 1101, 1103, 1104, 1106, 1107, 1070, 1071, 1114, 1115, 1116)
  private lazy val healthTestColateralResolvedAlerts = Set((31, ValveModes.HOME), (31, ValveModes.AWAY), (31, ValveModes.VACATION), (29, ValveModes.HOME), (29, ValveModes.AWAY), (29, ValveModes.VACATION), (30, ValveModes.AWAY), (30, ValveModes.VACATION), (30, ValveModes.HOME), (28, ValveModes.AWAY), (28, ValveModes.VACATION), (28, ValveModes.HOME))
  /**
    * where alarminternalID-> Set[(alarmId, systemMode)]
    **/
  private lazy val alertChainReactionClearMap = Map[Int, Set[(Int, Int)]](
    1064 -> healthTestColateralResolvedAlerts, //auto zit
    1065 -> healthTestColateralResolvedAlerts, //auto zit
    1066 -> healthTestColateralResolvedAlerts, //auto zit
    1070 -> healthTestColateralResolvedAlerts, //manual zit
    1071 -> healthTestColateralResolvedAlerts, //manual zit
    1072 -> healthTestColateralResolvedAlerts //manual zit
  )

  /**
    * list of alerts that will that would trigger a auto resolution alert ==========>>
    **/
  private lazy val autoResolutionAlertTriggers = Map[Int, Set[Int]](
    10 -> Set(ValveModes.HOME), //Max Flow Rate
    11 -> Set(ValveModes.HOME), // Per Event Flow
    26 -> Set(ValveModes.HOME) // Flow Duration
  )
  //Set(1010, 1016, 1013)

  private lazy val alarmNotificationDeliveryFiltersEndpoints = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)


  def getMutedAlarmsSet: Set[Int] = mutedAlarmsInternalIds

  def isAlarmInfoLevel(severity: Int): Boolean = severity match {
    case AlarmSeverity.LOW =>
      true
    case _ =>
      false
  }

  def isAlarmAutoLog(alarmInternalId: Int): Boolean = getMutedAlarmsSet contains alarmInternalId

  def triggersAutoResolutionAlert(alarmId: Int, systemMode: Int): Boolean = {
    val modes = autoResolutionAlertTriggers get alarmId
    if (modes.isDefined && modes.nonEmpty && modes.get.contains(systemMode)) true else false
  }

  def resolveAlarmsCollaterally(alarmInternalId: Int, icdId: String): Unit = {
    val collateralResolvingAlarms = alertChainReactionClearMap get alarmInternalId

    alarmNotificationDeliveryFiltersEndpoints.GetByIcdId(icdId).onComplete {
      case Failure(ex) => logger.error("The following error happened trying to get pending alerts for:", ex)
      case Success(icdPendingAlerts) =>
        logger.info(s"successfully retrieved  alerts for $icdId alert internal id: $alarmInternalId  to check for pending alerts to resolve colaterally")

        val hasPendingAlert = icdPendingAlerts.isDefined && icdPendingAlerts.get.nonEmpty

        if (collateralResolvingAlarms.isDefined && collateralResolvingAlarms.nonEmpty) {
          collateralResolvingAlarms.get.foreach((alarmAndSystemMode) => {
            val alarmId = alarmAndSystemMode._1
            val systemMode = alarmAndSystemMode._2
            if (hasPendingAlert) {

              logger.info(s"pending alerts found for $icdId alert internal id: $alarmInternalId ")
              val pendingAlert = icdPendingAlerts.get.find(alert => alert.systemMode.get == systemMode && alert.alarmId.get == alarmId && alert.status.get == AlarmNotificationStatuses.UNRESOLVED)
              if (pendingAlert.isDefined)
                resolvePendingAlert(pendingAlert.get)
            }
          })
        }
    }
  }

  /**
    * This method will return true if any of the users attached to an icd has the alarm muted, it will return false otherwise
    **/
  def hasUserMutedTheAlarm(userIcdAlarmDeliveryRules: ParSet[UserAlarmNotificationDeliveryRules]): Boolean = {
    val muted = userIcdAlarmDeliveryRules.find(rule => rule.isMuted.get)
    if (muted.isDefined && muted.nonEmpty) {
      val isMuted = muted.get.isMuted.getOrElse(false)
      if (isMuted) {
        logger.info(s"user id: ${muted.get.userId} has muted alarm id: ${muted.get.alarmId} system mode: ${muted.get.systemMode} internal id: ${muted.get.internalId} location id: ${muted.get.locationId}")
      }
      isMuted
    }
    else
      false
  }

  private def resolvePendingAlert(alert: AlarmNotificationDeliveryFilters): Unit = {
    alarmNotificationDeliveryFiltersEndpoints.Put(
      Some(
        AlarmNotificationDeliveryFilters(
          icdId = alert.icdId,
          alarmId = alert.alarmId,
          systemMode = alert.systemMode,
          createdAt = alert.createdAt,
          updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          expiresAt = alert.expiresAt,
          lastDecisionUserId = None,
          status = Some(AlarmNotificationStatuses.RESOLVED),
          lastIcdAlarmIncidentRegistryId = alert.lastIcdAlarmIncidentRegistryId,
          incidentTime = alert.incidentTime,
          severity = alert.severity
        )
      )
    ).onComplete {
      case Success(filter) =>

        logger.info(s"resolvePendingAlert Alert alarmID: ${alert.alarmId.getOrElse("n/a")} system mode: ${alert.systemMode.getOrElse("n/a")} was successfully resolved via collateral update")

      case Failure(e) =>

        logger.error(s"resolvePendingAlert The following error happened trying to trying to update alarmId: ${alert.alarmId} system mode: ${alert.systemMode.getOrElse("n/a")} exception: ${e.toString}")

    }
  }

  def getFilterStatusByAlertSeverityAndIsAlarmAutoLogAndIsAlarmMuted(severity: Int, internalId: Int, isMuted: Boolean, status: Int) = {
    val isInfoLevel = isAlarmInfoLevel(severity)
    val isAutoLog = isAlarmAutoLog(internalId)
    if (isInfoLevel || isAutoLog || isMuted) {
      if (isMuted) {
        AlarmNotificationStatuses.MUTED
      }
      else {
        AlarmNotificationStatuses.RESOLVED
      }
    }
    else if (!isMuted && status == AlarmNotificationStatuses.MUTED) {
      logger.info(s"Alarm internal id: $internalId was muted, now is unresolve since users changed preferences")
      AlarmNotificationStatuses.UNRESOLVED
    }
    else {
      status
    }
  }

}
