package flo.services

import com.flo.notification.sdk.service.NotificationService
import com.twitter.logging.Logger
import flo.models.http.{AlarmResponse, UserActions}

import scala.collection.SortedMap
import scala.concurrent.duration.Duration
import scala.concurrent.{Await, ExecutionContext, Future}
import scala.util.control.NonFatal

trait AlarmCache {
  def getAlarms: Map[String, SortedMap[Int, AlarmResponse]]
}

class AlarmCacheUpdater(notificationService: NotificationService, localizationService: LocalizationService)(
    implicit ec: ExecutionContext
) extends AlarmCache {

  private val log = Logger.get(getClass)

  @volatile private var cache: Map[String, SortedMap[Int, AlarmResponse]] = Map()

  def run(): Future[Unit] = Future {
    while (true) {
      log.info("Updating alarm cache.")

      val eventualAlarmMap = buildAlarmMap()
      try {
        val alarmResponse = Await.result(eventualAlarmMap, Duration.Inf)
        cache = alarmResponse
        log.info("Alarm cache updated successfully.")
        Thread.sleep(30000)
      } catch {
        case NonFatal(e) =>
          if (cache.isEmpty) {
            log.error(e, "Error while populating alarm cache for the first time.")
            Thread.sleep(5000)
          } else {
            log.warning(e, "Error while updating alarm cache.")
            Thread.sleep(30000)
          }
      }
    }
  }

  override def getAlarms: Map[String, SortedMap[Int, AlarmResponse]] = cache

  private def buildAlarmMap(): Future[Map[String, SortedMap[Int, AlarmResponse]]] = {
    val eventualAlarms                   = notificationService.getAlarmsByFilter(None, None, None)
    val eventualActionsAndSupportOptions = notificationService.getAlertActionsAndSupportOptions
    val eventualSettings                 = notificationService.getAllAlarmSystemModeSettings("personal")
    val eventualFeedbackFlows            = notificationService.retrieveAlertFeedbackFlows
    val eventualUserFeedbackOptions      = notificationService.retrieveUserFeedbackOptions

    for {
      alarms                         <- eventualAlarms
      actionsAndSupportOptions       <- eventualActionsAndSupportOptions
      alarmSystemModeSettings        <- eventualSettings.map(_.groupBy(_.alarmId))
      englishDisplayNames            <- localizationService.getLocalizedAlarmsDisplayName(alarms.map(_.id.toString).toSet, "en-us")
      frenchDisplayNames             <- localizationService.getLocalizedAlarmsDisplayName(alarms.map(_.id.toString).toSet, "fr-ca")
      feedbackFlows                  <- eventualFeedbackFlows
      userFeedbackOptions            <- eventualUserFeedbackOptions
      englishLocalizedSupportOptions <- localizationService.localizeActionSupportList(actionsAndSupportOptions, "en-us")
      frenchLocalizedSupportOptions  <- localizationService.localizeActionSupportList(actionsAndSupportOptions, "fr-ca")
      englishLocalizedFeedbackFlows  <- localizationService.localizeFeedbackFlows(feedbackFlows, "en-us")
      frenchLocalizedFeedbackFlows   <- localizationService.localizeFeedbackFlows(feedbackFlows, "fr-ca")
      englishLocalizedActionTitle    <- localizationService.localizeActionDisplayNameAndDescription("en-us")
      frenchLocalizedActionTitle     <- localizationService.localizeActionDisplayNameAndDescription("fr-ca")
      englishLocalizedUserFeedbackOptions <- localizationService.localizeUserFeedbackOptions(
                                              userFeedbackOptions,
                                              "en-us"
                                            )
      frenchLocalizedUserFeedbackOptions <- localizationService.localizeUserFeedbackOptions(
                                             userFeedbackOptions,
                                             "fr-ca"
                                           )
    } yield {
      val englishGroupedFeedbackFlows       = englishLocalizedFeedbackFlows.groupBy(_.alarmId)
      val frenchGroupedFeedbackFlows        = frenchLocalizedFeedbackFlows.groupBy(_.alarmId)
      val englishGroupedSupportOptions      = englishLocalizedSupportOptions.groupBy(_.alarmId)
      val frenchGroupedSupportOptions       = frenchLocalizedSupportOptions.groupBy(_.alarmId)
      val englishGroupedUserFeedbackOptions = englishLocalizedUserFeedbackOptions.groupBy(_.id)
      val frenchGroupedUserFeedbackOptions  = frenchLocalizedUserFeedbackOptions.groupBy(_.id)

      val englishAlarms = alarms.map { alarm =>
        val maybeActionSupport = englishGroupedSupportOptions.get(alarm.id)
        AlarmResponse.from(
          alarm,
          UserActions(
            englishLocalizedActionTitle.displayName,
            englishLocalizedActionTitle.description,
            maybeActionSupport.map(actionSupportList => actionSupportList.flatMap(_.actions)).getOrElse(Nil).toList
          ),
          maybeActionSupport
            .map(actionSupportList => actionSupportList.flatMap(_.supportOptions))
            .getOrElse(Nil)
            .toList,
          alarmSystemModeSettings.getOrElse(alarm.id, Seq()),
          englishDisplayNames.getOrElse(alarm.id.toString, DisplayNameAndDescription.empty()),
          englishGroupedFeedbackFlows.get(alarm.id),
          alarm.userFeedbackOptionsId.flatMap(id => englishGroupedUserFeedbackOptions.get(id).map(_.head))
        )
      }

      val frenchAlarms = alarms.map { alarm =>
        val maybeActionSupport = frenchGroupedSupportOptions.get(alarm.id)
        AlarmResponse.from(
          alarm,
          UserActions(
            frenchLocalizedActionTitle.displayName,
            frenchLocalizedActionTitle.description,
            maybeActionSupport.map(actionSupportList => actionSupportList.flatMap(_.actions)).getOrElse(Nil).toList
          ),
          maybeActionSupport
            .map(actionSupportList => actionSupportList.flatMap(_.supportOptions))
            .getOrElse(Nil)
            .toList,
          alarmSystemModeSettings.getOrElse(alarm.id, Seq()),
          frenchDisplayNames.getOrElse(alarm.id.toString, DisplayNameAndDescription.empty()),
          frenchGroupedFeedbackFlows.get(alarm.id),
          alarm.userFeedbackOptionsId.flatMap(id => frenchGroupedUserFeedbackOptions.get(id).map(_.head))
        )
      }

      val englishAlarmsMap = SortedMap(englishAlarms.map(a => (a.id, a)): _*)
      val frenchAlarmsMap  = SortedMap(frenchAlarms.map(a => (a.id, a)): _*)

      // We can do this as long as there are no differences between "en" and "en-us" (same for French).
      Map(
        "en"    -> englishAlarmsMap,
        "en-us" -> englishAlarmsMap,
        "fr"    -> frenchAlarmsMap,
        "fr-ca" -> frenchAlarmsMap
      )
    }
  }
}
