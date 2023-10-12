package flo.controllers

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

import com.flo.notification.sdk.model._
import com.flo.notification.sdk.model.statistics.{BatchStatisticsFilter, Statistics, Filter => FilterStatistics}
import com.flo.notification.sdk.service.{IncidentWithAlarmInfo => _, _}
import com.jakehschwartz.finatra.swagger.SwaggerController
import com.twitter.bijection.Conversion.asMethod
import com.twitter.bijection.twitter_util.UtilBijections
import com.twitter.finagle.http.MediaType
import com.twitter.util.{Future => TwitterFuture}
import flo.models.http._
import flo.services._
import flo.util.TypeConversionImplicits._
import io.circe.generic.auto._
import io.circe.syntax._
import io.swagger.models.Swagger
import javax.inject.{Inject, Provider, Singleton}
import org.json4s.DefaultFormats
import org.json4s.jackson.JsonMethods.parse

import scala.concurrent.{ExecutionContext, Future}
import com.softwaremill.quicklens._
import com.twitter.finatra.http.response.ResponseBuilder
import flo.util.Random

@Singleton
class NotificationController @Inject()(alarmCache: AlarmCache,
                                       service: NotificationService,
                                       s: Swagger,
                                       gateway: Provider[GatewayService],
                                       localizationService: LocalizationService,
                                       twilioService: TwilioService)(
    implicit ec: ExecutionContext
) extends SwaggerController
    with UtilBijections {
  implicit protected val swagger = s

  implicit lazy val formats = DefaultFormats.lossless

  getWithDoc("/alarms/:id") { o =>
    o.summary(
        "This endpoint will return the alarms by id"
      )
      .tag("Alarms")
      .routeParam[String]("id", "Alarm id")
      .responseWith(
        200,
        "Return an alarm by id",
        Some(AlarmResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        404,
        "Alert not found"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ByIntIdRequest =>
    val locale = request.lang.getOrElse("en-us")
    val alarmResponse = alarmCache.getAlarms
      .get(locale)
      .filter(_ => request.accountType == "personal")
      .flatMap(_.get(request.id))
      .map(alarm => Future.successful(Option(alarm)))
      .getOrElse {
        val eventualAlarm = service.getAlarm(request.id)
        val eventualActionsAndSupportOptions =
          service.getAlertActionsAndSupportOptions.map(_.find(_.alarmId == request.id))
        val eventualAlarmSystemModeSettings = service.getAlarmSystemModeSettings(request.id, request.accountType)
        val eventualAlarmDisplayName        = localizationService.getLocalizedAlarmDisplayName(request.id.toString, locale)
        val eventualFeedbackFlows           = service.retrieveAlertFeedbackFlows(request.id)
        val eventualUserFeedbackOptions     = service.retrieveUserFeedbackOptions(request.id)

        for {
          alarm                    <- eventualAlarm
          actionsAndSupportOptions <- eventualActionsAndSupportOptions
          alarmSystemModeSettings  <- eventualAlarmSystemModeSettings
          alarmDisplayName         <- eventualAlarmDisplayName
          feedbackFlows            <- eventualFeedbackFlows
          userFeedbackOptions      <- eventualUserFeedbackOptions

          localizedFeedbackFlows <- localizationService.localizeFeedbackFlows(feedbackFlows, locale)
          localizedSupportOptions <- actionsAndSupportOptions
                                      .map(opts => localizationService.localizeActionSupportList(Seq(opts), locale))
                                      .getOrElse(Future.successful(Seq()))
          localizedActionTitle <- localizationService.localizeActionDisplayNameAndDescription(locale)
          localizedFeedbackOptions <- userFeedbackOptions
                                       .map(opts => localizationService.localizeUserFeedbackOptions(Seq(opts), locale))
                                       .getOrElse(Future.successful(Seq()))
        } yield {
          alarm.map(
            AlarmResponse.from(
              _,
              UserActions(
                localizedActionTitle.displayName,
                localizedActionTitle.description,
                localizedSupportOptions.headOption.map(_.actions).getOrElse(Nil)
              ),
              localizedSupportOptions.headOption.map(_.supportOptions).getOrElse(Nil),
              alarmSystemModeSettings,
              alarmDisplayName,
              localizedFeedbackFlows.headOption.flatMap(_ => Some(localizedFeedbackFlows)),
              localizedFeedbackOptions.headOption
            )
          )
        }
      }
      .map { maybeAlarm =>
        maybeAlarm.map { alarm =>
          alarm
            .modify(_.userFeedbackFlow.each)
            .using(Random.randomizeFeedbackFlows(_, request.userId))
            .modify(_.feedbackOptions.each)
            .using(Random.randomizeUserFeedbackOptions(_, alarm.id, request.userId))
        }
      }

    alarmResponse
      .as[TwitterFuture[Option[AlarmResponse]]]
      .map {
        case Some(alarm) => response.ok.json(alarm)
        case None        => response.notFound.jsonError
      }
  }

  getWithDoc("/alarms") { o =>
    o.summary(
        "This endpoint will return the alarms by filter"
      )
      .tag("Alarms")
      .routeParam[Boolean]("isInternal", "Alarm is internal")
      .routeParam[Boolean]("enabled", "Alarm is enabled")
      .routeParam[String]("severity", "Alarm severity")
      .queryParam[String]("lang", "Language code")
      .responseWith(
        200,
        "Return an alarms by filters",
        Some(ItemsResponse(List(AlarmResponse.example)))
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        404,
        "Alert not found"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: GetAlarmsByFilterRequest =>
    val locale = request.lang.getOrElse("en-us")
    val alarmsResponse = alarmCache.getAlarms
      .get(locale)
      .filter(_ => request.accountType == "personal")
      .map { cachedAlarms =>
        Future.successful(
          cachedAlarms.values
            .filter(x => request.severity.forall(x.severity == _))
            .filter(x => request.isInternal.forall(x.isInternal == _))
            .filter(x => request.enabled.forall(x.active == _))
            .toList
        )
      }
      .getOrElse {
        val eventualAlarms = service.getAlarmsByFilter(
          request.severity.map(Severity.fromString),
          request.isInternal,
          request.enabled
        )
        val eventualActionsAndSupportOptions = service.getAlertActionsAndSupportOptions
        val eventualSystemModeSettings =
          service.getAllAlarmSystemModeSettings(request.accountType).map(_.groupBy(_.alarmId))
        val eventualFeedbackFlows       = service.retrieveAlertFeedbackFlows
        val eventualUserFeedbackOptions = service.retrieveUserFeedbackOptions

        for {
          alarms                       <- eventualAlarms
          actionsAndSupportOptions     <- eventualActionsAndSupportOptions
          alarmSystemModeSettings      <- eventualSystemModeSettings
          displayNames                 <- localizationService.getLocalizedAlarmsDisplayName(alarms.map(_.id.toString).toSet, locale)
          feedbackFlows                <- eventualFeedbackFlows
          userFeedbackOptions          <- eventualUserFeedbackOptions
          localizedFeedbackFlows       <- localizationService.localizeFeedbackFlows(feedbackFlows, locale)
          localizedSupportOptions      <- localizationService.localizeActionSupportList(actionsAndSupportOptions, locale)
          localizedActionTitle         <- localizationService.localizeActionDisplayNameAndDescription(locale)
          localizedUserFeedbackOptions <- localizationService.localizeUserFeedbackOptions(userFeedbackOptions, locale)
        } yield {
          val groupedFeedbackFlows       = localizedFeedbackFlows.groupBy(_.alarmId)
          val groupedSupportOptions      = localizedSupportOptions.groupBy(_.alarmId)
          val groupedUserFeedbackOptions = localizedUserFeedbackOptions.groupBy(_.id)
          alarms.map(
            alarm =>
              AlarmResponse.from(
                alarm,
                UserActions(
                  localizedActionTitle.displayName,
                  localizedActionTitle.description,
                  groupedSupportOptions.getOrElse(alarm.id, List()).flatMap(_.actions).toList
                ),
                groupedSupportOptions.getOrElse(alarm.id, List()).flatMap(_.supportOptions).toList,
                alarmSystemModeSettings.getOrElse(alarm.id, Seq()),
                displayNames.getOrElse(alarm.id.toString, DisplayNameAndDescription.empty()),
                groupedFeedbackFlows.get(alarm.id),
                alarm.userFeedbackOptionsId.flatMap(id => groupedUserFeedbackOptions.get(id).map(_.head))
            )
          )
        }
      }
      .map { alarms =>
        alarms.map { alarm =>
          alarm
            .modify(_.userFeedbackFlow.each)
            .using(Random.randomizeFeedbackFlows(_, request.userId))
            .modify(_.feedbackOptions.each)
            .using(Random.randomizeUserFeedbackOptions(_, alarm.id, request.userId))
        }
      }

    alarmsResponse
      .as[TwitterFuture[List[AlarmResponse]]]
      .map { alarms =>
        response.ok.json(ItemsResponse(alarms))
      }
  }

  postWithDoc("/events") { o =>
    o.summary(
        """This endpoint will create an alarm event that can result in a notification going to the user (aka send an alert).
          This endpoint will be used internally so regular users will be not able to use it"""
      )
      .tag("Notifications")
      .bodyParam[SendAlertRequest]("body", "Alert id, mac address and telemetry snapshot")
      .responseWith(
        200,
        "Send an alert and return an alert event id",
        Some(SendAlertResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: SendAlertRequest =>
    service.sendAlarm(request.macAddress, request.alarmId, request.telemetry).map { alarmIncidentId =>
      response.accepted.json(SendAlertResponse(alarmIncidentId))
    }
  }

  getWithDoc("/events/:id") { o =>
    o.summary(
        "This endpoint will return the alert event and its state by id"
      )
      .tag("Notifications")
      .routeParam[String]("id", "Event id of the alert that we want to send")
      .responseWith(
        200,
        "Return an alert event by id",
        Some(AlertEventResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        404,
        "Alert not found"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ByUUIDIdRequest =>
    val eventualIncidentWithAlarm = service.getIncidentById(request.id).as[TwitterFuture[Option[IncidentWithAlarmInfo]]]
    val eventualDeliveryEvents =
      service.getDeliveryEvents(Set(request.id)).as[TwitterFuture[Map[UUID, Seq[DeliveryEvent]]]]
    val eventualIncidentText =
      service
        .getIncidentTexts(Set(request.id), request.lang.getOrElse("en-us"), request.unitSystem.getOrElse("imperial"))
        .as[TwitterFuture[Seq[IncidentText]]]
    val eventualUserFeedback = service.retrieveUserFeedback(Set(request.id)).as[TwitterFuture[Seq[UserFeedback]]]

    eventualIncidentWithAlarm.flatMap {
      case Some(incidentWithAlarm) =>
        for {
          deliveryEventMap <- eventualDeliveryEvents
          incidentText     <- eventualIncidentText
          userFeedback     <- eventualUserFeedback
        } yield {
          val deliveryEvents = deliveryEventMap.getOrElse(request.id, Seq())
          val maybeTitle     = incidentText.headOption.flatMap(_.text.get("title").flatMap(_.headOption.map(_.value)))
          val maybeMessage   = incidentText.headOption.flatMap(_.text.get("message").flatMap(_.headOption.map(_.value)))

          val title = maybeTitle.getOrElse {
            alarmCache.getAlarms
              .get("en-us")
              .flatMap(
                _.get(incidentWithAlarm.alarm.id).map(_.displayName)
              )
              .getOrElse(incidentWithAlarm.alarm.name)
          }

          val message = maybeMessage.getOrElse("")
          val maybeUserFeedbackResponse = userFeedback.headOption.map { f =>
            UserFeedbackResponse(
              f.userId,
              f.feedback,
              f.feedback.headOption.fold("")(_.id),
              f.feedback.lift(1).fold("")(_.id),
              f.createdAt,
              f.updatedAt
            )
          }

          response.ok.json(
            AlertEventResponse(incidentWithAlarm, deliveryEvents, title, message, maybeUserFeedbackResponse)
          )
        }

      case None => TwitterFuture(response.notFound.jsonError)
    }
  }

  deleteWithDoc("/events/:id") { o =>
    o.summary(
        "This endpoint will delete an alert event by id"
      )
      .tag("Notifications")
      .routeParam[String]("id", "Event id of the alert that we want to remove")
      .responseWith(
        200,
        "Returns an empty json"
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        404,
        "Alert not found"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ByUUIDIdRequest =>
    service
      .deleteIncidentById(request.id)
      .as[TwitterFuture[Boolean]]
      .map {
        case true  => response.ok.json(EmptyResponse)
        case false => response.noContent.jsonError
      }
  }

  getWithDoc("/events") { o =>
    o.summary(
        "This will return the alert events for the account alert in a paginated way. " +
          "This will have the ability to filter the result by device or location."
      )
      .tag("Notifications")
      .queryParam[Seq[String]](
        "locationId",
        "The location where lives the device that created the alerts. You can use this param multiple times.",
        false
      )
      .queryParam[Seq[String]](
        "deviceId",
        "The deviceId of the device that created the alerts. You can use this param multiple times.",
        false
      )
      .queryParam[String]("accountId", "The accountId of the device that created the alerts", false)
      .queryParam[String]("groupId", "The groupId of the device that created the alerts", false)
      .queryParam[String](
        "createdAt",
        "Date on which events where created. You can have multiple of this arguments with this shape: arg=gt:2019-10-01T22:03:09. The date should be in UTC. Other operators are: eq, lt, let, gt, get",
        false
      )
      .queryParam[String](
        "status",
        "Alarm event status. You can use this param multiple times.",
        false
      )
      .queryParam[String](
        "reason",
        "Alarm event status reason. You can use this param multiple times.",
        false
      )
      .queryParam[String](
        "severity",
        "Alert severity. You can use this param multiple times.",
        false
      )
      .queryParam[String](
        "isInternalAlarm",
        "Filter by Alert that are internal or not.",
        false
      )
      .queryParam[String]("lang", "Language in which we want to receive the messages", false)
      .queryParam[String]("unitSystem", "Unit System", false)
      .queryParam[String]("page", "Page", false)
      .queryParam[String]("size", "Page size", false)
      .responseWith(
        200,
        "Alert event list in a paginated way",
        Some(ListAlertEventsResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ListAlertEventsRequest =>
    retrieveEvents(
      request.locationId,
      request.deviceId,
      request.accountId,
      request.groupId,
      request.createdAt,
      request.severity,
      request.status,
      request.reason,
      request.isInternalAlarm,
      request.lang,
      request.unitSystem,
      request.page,
      request.size
    )
  }

  postWithDoc("/events/batch") { o =>
    o.tag("Notifications")
  } { request: EventSearchRequest =>
    retrieveEvents(
      request.locationId.toSeq,
      request.deviceId.toSeq,
      request.accountId,
      request.groupId,
      request.createdAt.toSeq,
      request.severity.toSeq,
      request.status.toSeq,
      request.reason.toSeq,
      request.isInternalAlarm,
      request.lang,
      request.unitSystem,
      request.page,
      request.size,
      request.alarmId.toSeq
    )
  }

  putWithDoc("/events/move") { o =>
    o.summary("Move incidents by account and location")
      .tag("Notifications")
  } { request: MoveIncidentsRequest =>
    service
      .moveIncidents(
        request.deviceId,
        request.srcAccountId,
        request.destAccountId,
        request.srcLocationId,
        request.destLocationId
      )
      .as[TwitterFuture[Unit]]
      .map(_ => response.noContent)
  }

  putWithDoc("/alarms/clear") { o =>
    o.summary("This endpoint will clear a group of alarm ids.")
      .tag("Notifications")
      .bodyParam[ClearAlertsBody](
        "data",
        "An object containing the alarmIds, deviceId or locationId and the number of seconds we want to snooze in seconds the alert."
      )
      .responseWith(
        200,
        "This will return the number of cleared events",
        Some(ClearAlertResponse(3))
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ClearAlertsRequest =>
    clearAlarms(
      request.locationId.map(UUID.fromString),
      request.userId.map(UUID.fromString),
      request.devices,
      request.alarmIds,
      request.snoozeSeconds
    )
  }

  // TODO: Make this be driven by locationId and refined by deviceId like in the other clear alarm endpoint, also change auth on api gateway
  putWithDoc("/alarms/:alarmId/clear") { o =>
    o.summary("This endpoint will clear a specific alert type for a device in an account.")
      .tag("Notifications")
      .routeParam[Int]("alarmId", "The alarm id of the alerts we want to clear")
      .bodyParam[ClearAlertBody](
        "data",
        "An object containing the deviceId or locationId and the number of seconds we want to snooze in seconds the alert."
      )
      .responseWith(
        200,
        "This will return the number of cleared events",
        Some(ClearAlertResponse(3))
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: ClearAlertRequest =>
    clearAlarms(
      request.locationId.map(UUID.fromString),
      request.userId.map(UUID.fromString),
      request.devices,
      List(request.alarmId),
      request.snoozeSeconds
    )
  }

  getWithDoc("/settings/:userId") { o =>
    o.summary(
        "Retrieve alert settings by user, internal alarms are not returned by this endpoint." +
          "This will be the delivery config for each alarm and mode on each location/device."
      )
      .tag("Notifications")
      .routeParam[String]("userId", "The user we want to retrieve settings from.")
      .queryParam[String]("devices", "A list of device ids separated with commas.")
      .responseWith(
        200,
        "This will return alert settings by user",
        Some(List(DeviceAlarmSettings.example))
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: AlertSettingsRequest =>
    val deviceIds   = request.devices.split(",").map(_.trim).toList
    val deviceUuids = deviceIds.map(UUID.fromString)
    val eventualUserAlarmSettings =
      service.getUserAlarmSettings(request.userId, deviceUuids).as[TwitterFuture[List[UserAlarmSettings]]]
    val eventualDeliverySettings =
      service
        .getDeliverySettingsInBulk(request.userId, deviceUuids, List(), request.accountType)
        .as[TwitterFuture[AlertDeliverySettings]]

    for {
      userAlarmSettings <- eventualUserAlarmSettings
      deliverySettings  <- eventualDeliverySettings
    } yield {
      val allSettings = deliverySettings.userNonDefined ++ deliverySettings.userDefined
      response.ok.json(DeviceAlarmSettings.build(allSettings, userAlarmSettings))
    }
  }

  postWithDoc("/settings/:userId/batch") { o =>
    o.summary(
        "Retrieve alert settings by user, internal alarms are not returned by this endpoint." +
          "This will be the delivery config for each alarm and mode on each location/device."
      )
      .tag("Notifications")
      .routeParam[String]("userId", "The user we want to retrieve settings from.")
      .responseWith(
        200,
        "This will return alert settings by user"
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: BatchAlertSettingsRequest =>
    if (request.deviceIds.nonEmpty && request.locationIds.nonEmpty) {
      TwitterFuture(response.badRequest.jsonError("Invalid parameters: Either locationIds or deviceIds expected."))
    } else {
      if (request.deviceIds.nonEmpty) {
        val deviceUuids = request.deviceIds.map(UUID.fromString).toList
        val eventualUserAlarmSettings =
          service.getUserAlarmSettings(request.userId, deviceUuids).as[TwitterFuture[List[UserAlarmSettings]]]
        val eventualDeliverySettings =
          service
            .getDeliverySettingsInBulk(request.userId, deviceUuids, List(), request.accountType)
            .as[TwitterFuture[AlertDeliverySettings]]

        for {
          userAlarmSettings <- eventualUserAlarmSettings
          deliverySettings  <- eventualDeliverySettings
        } yield {
          val allSettings = deliverySettings.userNonDefined ++ deliverySettings.userDefined
          response.ok.json(
            BatchDeviceAlarmSettings(
              DeviceAlarmSettings.build(allSettings, userAlarmSettings, Option(deliverySettings.userDefined))
            )
          )
        }
      } else {
        val locationUuids = request.locationIds.map(UUID.fromString).toList
        val eventualDeliverySettings =
          service
            .getDeliverySettingsInBulk(request.userId, List(), locationUuids, request.accountType)
            .as[TwitterFuture[AlertDeliverySettings]]

        for {
          deliverySettings <- eventualDeliverySettings
        } yield {
          val allSettings = deliverySettings.userNonDefined ++ deliverySettings.userDefined
          response.ok.json(BatchLocationAlertSettingsResponse.build(allSettings, deliverySettings.userDefined))
        }
      }
    }
  }

  postWithDoc("/settings/:userId") { o =>
    o.summary(
        "Update alert settings by user, internal alarms are not returned by this endpoint." +
          "This will be the delivery config for each alarm and mode on a device."
      )
      .tag("Notifications")
      .routeParam[String]("userId", "The user we want to update settings to.")
      .bodyParam[List[DeviceAlarmSettings]](
        "items",
        "An object containing the deviceId, and 3 arrays: info settings, warning settings and critical settings. " +
          "Each array will contain objects of alarmId, systemMode and an optional flag for each delivery medium."
      )
      .responseWith(
        200,
        "This will return an empty json",
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: UpdateSettingsRequest =>
    val deviceSettings =
      request.items.withFilter(_.deviceId.isDefined).map(s => s.deviceId.get -> s)(scala.collection.breakOut)
    val locationSettings =
      request.items.withFilter(_.locationId.isDefined).map(s => s.locationId.get -> s)(scala.collection.breakOut)

    val eventualDeviceSettings = if (deviceSettings.nonEmpty) {
      val userAlarmSettings = deviceSettings.map {
        case (deviceId, s) =>
          UserAlarmSettings(
            request.userId,
            UUID.fromString(deviceId),
            s.floSenseLevel,
            s.smallDripSensitivity
          )
      }.toList

      val eventualUserAlarmSettings = service.saveUserAlarmSettings(userAlarmSettings).as[TwitterFuture[Unit]]

      val eventualDeliverySettings = service
        .saveDeliverySettings(
          request.userId,
          UpdateSettingsRequest.toAlarmDeliverySettings(request),
          request.accountType
        )
        .as[TwitterFuture[Boolean]]

      TwitterFuture.join(Seq(eventualUserAlarmSettings, eventualDeliverySettings))
    } else TwitterFuture.Done

    val eventualLocationSettings = if (locationSettings.nonEmpty) {
      service
        .saveDeliverySettings(
          request.userId,
          UpdateSettingsRequest.toAlarmDeliverySettings(request),
          request.accountType
        )
        .as[TwitterFuture[Boolean]]
    } else TwitterFuture.Done

    TwitterFuture
      .join(eventualDeviceSettings, eventualLocationSettings)
      .map(_ => response.ok.json(EmptyResponse()))
  }

  postWithDoc("/events/sample") { o =>
    o.summary("Generate random events for testing purposes only")
      .tag("Notifications")
      .bodyParam[RandomEventsRequest]("body", "userId and deviceId we want to generate events for.")
      .responseWith(
        200,
        "This will return an empty json",
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: RandomEventsRequest =>
    val gatewayService = gateway.get

    gatewayService
      .getUserWithLocations(request.userId)
      .as[TwitterFuture[Option[User]]]
      .flatMap {
        case Some(user) =>
          user.getLocationByDevice(request.deviceId)

          service
            .generateRandomIncidents(
              request.userId,
              request.deviceId,
              user.getLocationByDevice(request.deviceId).get.id
            )
            .as[TwitterFuture[Boolean]]
            .map(_ => response.ok.json(EmptyResponse()))

        case None => TwitterFuture(response.notFound.jsonError("User id not found"))
      }
  }

  getWithDoc("/actions") { o =>
    o.summary("This endpoint will return a series of alert actions and support options for each alert.")
      .tag("Notifications")
      .responseWith(
        200,
        "This will return a series of alert actions and support options for each alert.",
        Some(ActionsSupportResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { _: {} =>
    service.getAlertActionsAndSupportOptions
      .as[TwitterFuture[List[ActionSupport]]]
      .map(res => response.ok.json(ActionsSupportResponse(res)))
  }

  getWithDoc("/statistics") { o =>
    o.summary("Retrieve alert statistics.")
      .tag("Notifications")
      .queryParam[String]("from", "Date time in ISO format", false)
      .queryParam[String]("to", "Date time in ISO format", false)
      .queryParam[String]("deviceId", "Filter events by device id", false)
      .queryParam[String]("accountId", "Filter events by account id", false)
      .queryParam[String]("locationId", "Filter events by location id", false)
      .queryParam[String]("groupId", "Filter events by group id", false)
      .responseWith(
        200,
        "This will return a series of alert actions and support options for each alert.",
        Some(StatisticsResponse.example)
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { req: StatisticsRequest =>
    {
      val formatter = DateTimeFormatter.ISO_DATE_TIME
      service
        .retrieveStatistics(
          FilterStatistics(
            req.from.map(LocalDateTime.parse(_, formatter)),
            req.to.map(LocalDateTime.parse(_, formatter)),
            req.accountId.map(UUID.fromString),
            req.locationId.map(UUID.fromString),
            req.deviceId.map(UUID.fromString),
            req.groupId.map(UUID.fromString)
          )
        )
        .as[TwitterFuture[Statistics]]
        .map(res => response.ok.json(StatisticsResponse(res, alarmCache.getAlarms.getOrElse("en-us", Map()).toMap)))
    }
  }

  postWithDoc("/statistics/batch") { o =>
    o.summary("Retrieve alert statistics.")
      .tag("Notifications")
  } { req: StatisticsRequestBatch =>
    service
      .retrieveStatistics(
        BatchStatisticsFilter(
          req.locationIds.map(_.map(UUID.fromString)),
          req.deviceIds.map(_.map(UUID.fromString))
        )
      )
      .as[TwitterFuture[Statistics]]
      .map(res => response.ok.json(StatisticsResponse(res, alarmCache.getAlarms.getOrElse("en-us", Map()).toMap)))
  }

  post("/cache/refresh") { req: RefreshCacheRequest =>
    service
      .refreshStatsCache(req.deviceIds)
      .map { _ =>
        response.noContent
      }
  }

  get("/delivery/system/version/:userId") { request: DeliverySystemVersionRequest =>
    val userId = request.userId
    response.ok.json(s"""{"userId":"$userId","version":2}""")
  }

  post("/voice/gather/user-action/:userId/:incidentId") { request: GatherUserActionRequest =>
    val gatewayService  = gateway.get
    val voiceRequestLog = VoiceRequestLog(request.incidentId, request.userId, request.rawData)

    val eventualIncident    = service.getIncidentById(request.incidentId).as[TwitterFuture[Option[IncidentWithAlarmInfo]]]
    val eventualLogCreation = service.createVoiceRequestLog(voiceRequestLog).as[TwitterFuture[Unit]]
    val eventualDeliveryEvent =
      service.getDeliveryEvents(Set(request.incidentId)).as[TwitterFuture[Map[UUID, Seq[DeliveryEvent]]]]

    val eventualResponse = for {
      maybeIncidentWithAlarm <- eventualIncident
      deliveryEventMap       <- eventualDeliveryEvent
      _                      <- eventualLogCreation
    } yield {

      deliveryEventMap.get(request.incidentId).foreach { deliveryEvents =>
        deliveryEvents
          .find(e => e.medium == DeliveryEventMedium.VoiceCall && e.userId == UUID.fromString(request.userId))
          .foreach { deliveryEvent =>
            val updatedDeliveryEvent = deliveryEvent.copy(
              status = DeliveryMediumStatus.Delivered,
              info = request.rawData,
              updateAt = LocalDateTime.now()
            )
            service.upsertDeliveryEvent(updatedDeliveryEvent)
          }
      }

      maybeIncidentWithAlarm match {
        case None => TwitterFuture(response.notFound.jsonError("Incident not found."))

        case Some(incidentWithAlarmInfo) =>
          twilioService
            .processUserAction(request.digits, incidentWithAlarmInfo)
            .flatMap { _ =>
              val systemMode = incidentWithAlarmInfo.incident.systemMode
              gatewayService.getUserUnsafe(UUID.fromString(request.userId)).flatMap { maybeUser =>
                val userLocale = maybeUser.map(_.locale).getOrElse("en-us")
                twilioService.buildTwilioResponse(request.digits, systemMode, request.gatherUrl, userLocale)
              }
            }
            .as[TwitterFuture[String]]
            .map { twilioResponse =>
              response.ok(twilioResponse).contentType(MediaType.Xml)
            }
      }
    }
    eventualResponse.flatMap(identity)
  }

  post("/voice/status/:incidentId/:userId") { request: VoiceCallStatusRequest =>
    val eventualDeliveryEvent =
      service.getDeliveryEvents(Set(request.incidentId)).as[TwitterFuture[Map[UUID, Seq[DeliveryEvent]]]]

    eventualDeliveryEvent.map { deliveryEventMap =>
      deliveryEventMap.get(request.incidentId).foreach { deliveryEvents =>
        deliveryEvents
          .find(e => e.medium == DeliveryEventMedium.VoiceCall && e.userId == UUID.fromString(request.userId))
          .foreach { deliveryEvent =>
            val updatedDeliveryEvent = deliveryEvent.copy(
              status = DeliveryMediumStatus.fromString(request.callStatus),
              info = request.data,
              updateAt = LocalDateTime.now()
            )
            service.upsertDeliveryEvent(updatedDeliveryEvent)
          }
      }
    }

    response.ok
  }

  post("/push/status/:incidentId/:userId") { request: PushStatusRequest =>
    val eventualDeliveryEvent =
      service.getDeliveryEvents(Set(request.incidentId)).as[TwitterFuture[Map[UUID, Seq[DeliveryEvent]]]]

    eventualDeliveryEvent.map { deliveryEventMap =>
      deliveryEventMap.get(request.incidentId).foreach { deliveryEvents =>
        deliveryEvents
          .find(e => e.medium == DeliveryEventMedium.PushNotification && e.userId == UUID.fromString(request.userId))
          .foreach { deliveryEvent =>
            val updatedDeliveryEvent = deliveryEvent.copy(
              status = DeliveryMediumStatus.fromString(request.status),
              updateAt = LocalDateTime.now()
            )
            service.upsertDeliveryEvent(updatedDeliveryEvent)
          }
      }
    }

    response.ok
  }

  postWithDoc("/email/events") { o =>
    o.summary("Web hook to update the email statuses from SendGrid")
      .tag("Notifications")
      .bodyParam[SendGridEventsRequest]("body")
      .responseWith(
        200,
        "This will return an empty json",
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: SendGridEventsRequest =>
    val result = request.events.map { event =>
      DeliveryMediumStatus.fromSendGridEmailEvent(event.event) match {
        case Some(status) =>
          val metadata = parse(event.asJson.noSpaces).extract[Map[String, Any]]

          service.updateDeliveryEvent(event.receiptId, status, metadata)
        case None => Future.unit
      }
    }

    Future
      .sequence(result)
      .as[TwitterFuture[List[Unit]]]
      .map(_ => response.ok.json("Success"))
  }

  postWithDoc("/email/events/:incidentId/:userId") { o =>
    o.summary("Web hook to update the sms statuses from Twilio")
      .tag("Notifications")
      .bodyParam[EmailServiceEventRequest]("body")
      .responseWith(
        200,
        "This will return an empty json",
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: EmailServiceEventRequest =>
    val metadata = parse(request.asJson.noSpaces).extract[Map[String, Any]]

    service
      .updateDeliveryEvent(
        request.incidentId,
        request.userId,
        DeliveryEventMedium.Email,
        request.receiptId,
        DeliveryMediumStatus.Triggered,
        metadata
      )
      .as[TwitterFuture[Unit]]
      .map(_ => response.ok.json("Success"))
  }

  postWithDoc("/sms/events/:incidentId/:userId") { o =>
    o.summary("Web hook to update the sms statuses from Twilio")
      .tag("Notifications")
      .bodyParam[SendGridEventsRequest]("body")
      .responseWith(
        200,
        "This will return an empty json",
      )
      .responseWith(
        401,
        "Access token is missing or invalid"
      )
      .responseWith(
        403,
        "Unauthorized access"
      )
  } { request: SmsStatusEventRequest =>
    val metadata = parse(request.asJson.noSpaces).extract[Map[String, Any]]

    service
      .updateDeliveryEvent(
        request.incidentId,
        request.userId,
        DeliveryEventMedium.Sms,
        request.smsSid,
        DeliveryMediumStatus.fromString(request.smsStatus),
        metadata
      )
      .as[TwitterFuture[Unit]]
      .map(_ => response.ok.json("Success"))
  }

  putWithDoc("/alerts/:incidentId/feedback") { o =>
    o.summary("Provide feedback about alert")
      .tag("Notifications")
      .routeParam[String]("incidentId", "The incident id to provide feedback about.")
      .queryParam[Boolean]("force", "Overwrite any previous feedback", false)
      .bodyParam[UserFeedbackRequest]("body")
      .responseWith(204)
      .responseWith(409, "Feedback was already given by another user.")
  } { request: UserFeedbackRequest =>
    val userFeedback = UserFeedback(
      request.incidentId,
      request.userId,
      request.options.map(f => FeedbackIdValue(f.id, f.value)),
      LocalDateTime.now(),
      LocalDateTime.now()
    )
    service
      .saveUserFeedback(userFeedback, request.force)
      .as[TwitterFuture[Boolean]]
      .map { success =>
        if (success) response.noContent
        else response.conflict.jsonError("Feedback was already given by another user.")
      }
  }

  private def clearAlarms(maybeLocationId: Option[UUID],
                          maybeUserId: Option[UUID],
                          devices: List[DeviceInfo],
                          alarmIds: List[Int],
                          snoozeSeconds: Int): TwitterFuture[ResponseBuilder#EnrichedResponse] =
    maybeLocationId
      .map { locationId =>
        service
          .clearIncidentsByLocation(
            locationId,
            devices.map(device => DeviceSimple(UUID.fromString(device.id), device.macAddress)),
            alarmIds,
            snoozeSeconds,
            maybeUserId
          )
          .as[TwitterFuture[Long]]
          .map(res => response.ok.json(ClearAlertResponse(res)))
      }
      .getOrElse {
        if (devices.isEmpty) {
          TwitterFuture(
            response.badRequest.jsonError("Invalid parameters: Either locationId or devices expected.")
          )
        } else {
          TwitterFuture
            .collect(
              devices
                .map { device =>
                  service
                    .clearIncidentsByIcd(
                      DeviceSimple(UUID.fromString(device.id.toString), device.macAddress),
                      alarmIds,
                      snoozeSeconds,
                      None,
                      maybeUserId
                    )
                    .as[TwitterFuture[Long]]
                }
            )
            .map(res => response.ok.json(ClearAlertResponse(res.sum)))
        }
      }

  private def retrieveEvents(locationId: Seq[String],
                             deviceId: Seq[String],
                             accountId: Option[String],
                             groupId: Option[String],
                             createdAt: Seq[String],
                             severity: Seq[String],
                             status: Seq[String],
                             reason: Seq[String],
                             isInternalAlarm: Option[Boolean],
                             lang: Option[String],
                             unitSystem: Option[String],
                             page: Option[Int],
                             size: Option[Int],
                             alarmId: Seq[Int] = Seq()): TwitterFuture[ResponseBuilder#EnrichedResponse] =
    if (groupId.isEmpty && deviceId.isEmpty && locationId.isEmpty) {
      TwitterFuture(
        response.badRequest.jsonError(
          "Invalid parameters: at least one groupId, deviceId or locationId must be provided."
        )
      )
    } else {
      val defaultPagination = Pagination()

      val eventualIncidentsWithAlarm = service
        .getIncidentsByFilter(
          locationId.map(UUID.fromString),
          deviceId.map(UUID.fromString),
          accountId.map(UUID.fromString),
          groupId.map(UUID.fromString),
          Filter.generateLocalDateTimeFilters(createdAt),
          Filter.generateFilters[Int](status, x => IncidentStatus.fromString(x)).map(x => x.value),
          Filter.generateFilters[Int](reason, x => IncidentReason.fromString(x)).map(x => x.value),
          Filter.generateFilters[Int](severity, x => Severity.fromString(x)).map(x => x.value),
          isInternalAlarm,
          Some(
            Pagination(
              page.getOrElse(defaultPagination.page),
              size.getOrElse(defaultPagination.size)
            )
          ),
          alarmId,
        )
        .as[TwitterFuture[PaginatedResult[IncidentWithAlarmInfo]]]

      eventualIncidentsWithAlarm.flatMap { incidentsWithAlarm =>
        val incidentIds = incidentsWithAlarm.items.map(_.incident.id).toSet
        val eventualDeliveryEvents = service
          .getDeliveryEvents(incidentIds)
          .as[TwitterFuture[Map[UUID, Seq[DeliveryEvent]]]]

        val eventualIncidentTexts =
          service
            .getIncidentTexts(incidentIds, lang.getOrElse("en-us"), unitSystem.getOrElse("imperial"))
            .as[TwitterFuture[Seq[IncidentText]]]

        val eventualUserFeedbacks =
          service.retrieveUserFeedback(incidentIds).as[TwitterFuture[Seq[UserFeedback]]]

        for {
          deliveryEvents <- eventualDeliveryEvents
          incidentTexts  <- eventualIncidentTexts
          userFeedbacks  <- eventualUserFeedbacks
        } yield {
          val textsByIncident     = incidentTexts.groupBy(_.incidentId)
          val feedbacksByIncident = userFeedbacks.groupBy(_.incidentId)

          val responseItems = incidentsWithAlarm.items.map { incidentWithAlarm =>
            val maybeIncidentText = textsByIncident.get(incidentWithAlarm.incident.id)
            val maybeTitle =
              maybeIncidentText.flatMap(_.headOption.flatMap(_.text.get("title").flatMap(_.headOption.map(_.value))))
            val maybeMessage =
              maybeIncidentText.flatMap(_.headOption.flatMap(_.text.get("message").flatMap(_.headOption.map(_.value))))

            val title = maybeTitle.getOrElse {
              alarmCache.getAlarms
                .get("en-us")
                .flatMap(
                  _.get(incidentWithAlarm.alarm.id).map(_.displayName)
                )
                .getOrElse(incidentWithAlarm.alarm.name)
            }

            val message = maybeMessage.getOrElse("")
            val maybeUserFeedbackResponse = feedbacksByIncident
              .get(incidentWithAlarm.incident.id)
              .map(_.head)
              .map(
                f =>
                  UserFeedbackResponse(
                    f.userId,
                    f.feedback,
                    f.feedback.headOption.fold("")(_.id),
                    f.feedback.lift(1).fold("")(_.id),
                    f.createdAt,
                    f.updatedAt
                )
              )

            AlertEventResponse(
              incidentWithAlarm,
              deliveryEvents.getOrElse(incidentWithAlarm.incident.id, Seq()),
              title,
              message,
              maybeUserFeedbackResponse
            )
          }

          response.ok.json(PaginatedResult(responseItems, incidentsWithAlarm.total))
        }
      }
    }
}
