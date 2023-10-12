package com.flo.notification.sdk.service

import java.net.InetAddress
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.time.{LocalDateTime, ZoneOffset, ZonedDateTime, Duration => JavaDuration}
import java.util.UUID

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.http.scaladsl.unmarshalling.Unmarshaller
import akka.pattern.RetrySupport
import akka.stream.ActorMaterializer
import akka.util.ByteString
import com.flo.FloApi.gateway.Devices
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsGrantInfo, FloTokenProviders, OAuth2AuthProvider}
import com.flo.communication.AsyncKafkaProducer
import com.flo.mqtt.IMQTTClient
import com.flo.notification.sdk.model.activity.{EntityActivity, EntityActivityItem}
import com.flo.notification.sdk.model.kafka.AlarmIncident
import com.flo.notification.sdk.model.statistics.{BatchStatisticsFilter, DeviceStat, Stat, Statistics, Filter => StatisticsFilter}
import com.flo.notification.sdk.model.{DeliveryEventMedium, Action => ActionModel, Alarm => AlarmModel, _}
import com.flo.notification.sdk.util.{LocalDateTimeExtensions, RandomDataGeneratorUtil}
import com.flo.utils.{FromCamelToSneakCaseSerializer, HttpMetrics, IHttpMetrics}
import com.github.blemale.scaffeine.{Cache, Scaffeine}
import com.softwaremill.quicklens._
import com.typesafe.config.Config
import io.getquill.{Embedded, PostgresJdbcContext, SnakeCase}
import kamon.Kamon
import org.json4s._
import org.json4s.jackson.JsonMethods._
import org.json4s.jackson.Serialization
import perfolation._
import redis.{ByteStringDeserializer, RedisCluster, RedisServer}

import scala.concurrent.duration.{Duration => ScalaDuration, _}
import scala.concurrent.{ExecutionContext, Future}

// TODO: Refactor ALL this file.

private case class Alarm(
                           id: Int,
                           name: String,
                           severity: Int,
                           isInternal: Boolean,
                           sendWhenValveIsClosed: Boolean,
                           enabled: Boolean,
                           userConfigurable: Boolean,
                           maxDeliveryFrequency: String,
                           parentId: Option[Int],
                           metadata: Map[String, Any],
                           tags: Set[String],
                           userFeedbackOptionsId: Option[Int]
                         ) extends Embedded {

  def toModel(parentChildren: Map[Int, Set[Int]] = Map()): AlarmModel = {
    AlarmModel(
      id = this.id,
      name = this.name,
      severity = this.severity,
      isInternal = this.isInternal,
      sendWhenValveIsClosed = this.sendWhenValveIsClosed,
      enabled = this.enabled,
      userConfigurable = this.userConfigurable,
      maxDeliveryFrequency = this.maxDeliveryFrequency,
      parentId = this.parentId,
      children = parentChildren.getOrElse(this.id, Set()),
      metadata = this.metadata,
      tags = this.tags,
      userFeedbackOptionsId = this.userFeedbackOptionsId
    )
  }
}

case object FeedbackOptionTypeSerializer extends CustomSerializer[FeedbackOptionType](_ => (
  {
    case JString(s) if s == "list" => ListType
    case JString(s) if s == "card" => CardType
    case JString(s) if s == "item" => ItemType
    case JString(s) if s == "text" => TextType
    case _                         => null
  },
  {
    case feedbackOption: FeedbackOptionType => JString(feedbackOption.toString)
  })
)

private case class IncidentWithAlarm(incident: Incident, alarm: Alarm)

private object IncidentWithAlarmInfo {
  def apply(incident: Incident, alarm: Alarm) = new IncidentWithAlarmInfo(incident, alarm.toModel())
}

class NotificationService(
                           kafkaProducer: AsyncKafkaProducer,
                           incidentTopic: Option[String],
                           entityActivityTopic: Option[String],
                           notificationsResponsePublisher: IMQTTClient,
                           databaseConfig: Config,
                           cacheConfig: Config,
                           fireWriterBaseUrl: String
                         ) (implicit ex: ExecutionContext, as: ActorSystem, am: ActorMaterializer) extends RandomDataGeneratorUtil {

  private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-public-gateway",
    tags = Map("service-name" -> "flo-notification-api-v2")
  )

  val simpleSerializer = new FromCamelToSneakCaseSerializer
  val serializeResponse = (response: NotificationResponse) => simpleSerializer.serialize[NotificationResponse](response)
  val serializeAck = (ack: AlertAck) => simpleSerializer.serialize[AlertAck](ack)

  val ctx = new PostgresJdbcContext(SnakeCase, databaseConfig) with LocalDateTimeExtensions

  type AlarmSystemModeSettingsId = Int

  implicit val formats = org.json4s.DefaultFormats ++ org.json4s.ext.JavaTimeSerializers.all ++ org.json4s.ext.JavaTypesSerializers.all ++ List(FeedbackOptionTypeSerializer)

  import ctx._

  implicit val jsonDecoder: Decoder[Map[String, Any]] =
    decoder((index, row) => {
      val input = Option(row.getObject(index)).map(_.toString).getOrElse("{}")
      parse(input).extract[Map[String, Any]] // database-specific implementation
    })

  implicit val jsonEncoder: Encoder[Map[String, Any]] =
    encoder(java.sql.Types.OTHER, (index, value, row) =>
      row.setObject(index, Serialization.write(value), java.sql.Types.OTHER)) // database-specific implementation

  implicit val localizedTextEncoder: Encoder[Map[String, Set[LocalizedText]]] =
    encoder(java.sql.Types.OTHER, (index, value, row) =>
      row.setObject(index, Serialization.write(value), java.sql.Types.OTHER)) // database-specific implementation

  implicit val localizedTextDecoder: Decoder[Map[String, Set[LocalizedText]]] =
    decoder((index, row) => {
      val input = Option(row.getObject(index)).map(_.toString).getOrElse("{}")
      parse(input).extract[Map[String, Set[LocalizedText]]] // database-specific implementation
    })

  implicit val jsonStringEncoder: Encoder[JsonString] =
    encoder(java.sql.Types.OTHER, (index, value, row) =>
      row.setObject(index, value.value, java.sql.Types.OTHER)) // database-specific implementation

  implicit val alertFeedbackStepDecoder: Decoder[AlertFeedbackStep] =
    decoder((index, row) => {
      val input = Option(row.getObject(index)).map(_.toString).getOrElse("{}")
      parse(input).camelizeKeys.extract[AlertFeedbackStep]
    })

  implicit val alertFeedbackStepMapDecoder: Decoder[Map[String, AlertFeedbackStep]] = {
    def snakify(name: String): String =
      name.replaceAll("([A-Z]+)([A-Z][a-z])", "$1_$2").replaceAll("([a-z\\d])([A-Z])", "$1_$2").toLowerCase

    decoder((index, row) => {
      val input = Option(row.getObject(index)).map(_.toString).getOrElse("{}")
      parse(input).camelizeKeys.extract[Map[String, AlertFeedbackStep]].map { case (k, v) =>
        snakify(k) -> v // We need to preserve the key as snake case
      }(scala.collection.breakOut)
    })
  }

  implicit val userFeedbackOptionsDecoder: Decoder[FeedbackOption] = {
    decoder((index, row) => {
      parse(row.getObject(index).toString).extract[FeedbackOption]
    })
  }

  implicit val userFeedbackOptionSeqDecoder: Decoder[Seq[FeedbackOption]] = {
    decoder((index, row) => {
      parse(row.getObject(index).toString).extract[Seq[FeedbackOption]]
    })
  }

  implicit val feedbackIdValueEncoder: Encoder[Seq[FeedbackIdValue]] = {
    encoder(java.sql.Types.OTHER, (index, value, row) =>
      row.setObject(index, Serialization.write(value), java.sql.Types.OTHER)) // database-specific implementation
  }

  implicit val feedbackIdValueDecoder: Decoder[Seq[FeedbackIdValue]] =
    decoder((index, row) => {
      val input = Option(row.getObject(index)).map(_.toString).getOrElse("[]")
      parse(input).extract[Seq[FeedbackIdValue]] // database-specific implementation
    })

  implicit val stringSetDecoder: MappedEncoding[String, Set[String]] = MappedEncoding[String, Set[String]] { s =>
    Option(s)
      .filterNot(_.isEmpty)
      .map(_.split(',').toSet)
      .getOrElse(Set())
  }
  implicit val stringSetEncoder: MappedEncoding[Set[String], String] =
    MappedEncoding[Set[String], String](_.toSeq.sorted.mkString(","))

  implicit val filterStateTypeEncoder: MappedEncoding[FilterStateType, Int] = MappedEncoding[FilterStateType, Int](FilterStateType.toId)

  implicit val filterStateTypeDecoder: MappedEncoding[Int, FilterStateType] = MappedEncoding[Int, FilterStateType](FilterStateType.fromIdUnsafe)

  private val nilUuid = new UUID(0, 0)

  private val redis = RedisCluster(InetAddress.getAllByName(cacheConfig.getString("host")).map { a =>
    RedisServer(a.getHostAddress, cacheConfig.getInt("port"))
  })

  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(as, am, httpMetrics)
  private val authProvider = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)
  private val device = new Devices()(authProvider)(as, am, httpMetrics)

  private val alarmCache: Cache[Int, AlarmModel] =
    Scaffeine()
      .recordStats()
      .expireAfterWrite(10.minutes)
      .maximumSize(500)
      .build[Int, AlarmModel]()

  private val DefaultAccountType = "personal"

  def getAlarmsByFilter(severity: Option[Int], isInternal: Option[Boolean], enabled: Option[Boolean]): Future[List[AlarmModel]] = {
    val alarmsQuery = dynamicQuery[Alarm]
      .filterOpt(severity)((alarm, severity) => quote(alarm.severity == severity))
      .filterOpt(isInternal)((alarm, isInternal) => quote(alarm.isInternal == isInternal))
      .filterOpt(enabled)((alarm, enabled) => quote(alarm.enabled == enabled))
      .sortBy(_.id)(Ord.asc)

    val eventualParentChildren = getParentChildrenAlarms
    val eventualAlarms = Future(ctx.run(alarmsQuery))

    for {
      parentChildren <- eventualParentChildren
      alarms <- eventualAlarms
    } yield {
      alarms.map(_.toModel(parentChildren))
    }
  }

  def sendAlarm(macAddress: String, alertId: Int, snapshot: Option[TelemetrySnapshot] = None): Future[String] = {
    val alarmIncident = AlarmIncident.build(alertId, macAddress, snapshot)

    incidentTopic.map { topic =>
      kafkaProducer.send[AlarmIncident](topic, alarmIncident, incident => Serialization.write(incident)).map { _ =>
        alarmIncident.id
      }
    }.getOrElse(Future.failed(new RuntimeException("No Incident topic configured.")))

  }

  def getIncidentById(id: UUID): Future[Option[IncidentWithAlarmInfo]] = {
    val incidentQuery = quote {
      for {
        incident <- query[Incident] if incident.id == lift(id)
        alarm <- query[Alarm] if incident.alarmId == alarm.id
      } yield {
        IncidentWithAlarm(incident, alarm)
      }
    }

    Future(ctx.run(incidentQuery))
      .map(_.headOption.map(incident => IncidentWithAlarmInfo(incident.incident, incident.alarm)))
  }

  def deleteIncidentById(id: UUID): Future[Boolean] = {
    val deleteQuery = quote {
      query[Incident].filter(_.id == lift(id)).delete
    }
    Future(ctx.run(deleteQuery)).map(x => x > 0)
  }

  def getIncidentsByFilter(
                              locationIds: Seq[UUID],
                              icdIds: Seq[UUID],
                              accountId: Option[UUID] = None,
                              groupId: Option[UUID] = None,
                              createdAt: Seq[Filter[LocalDateTime]] = Seq(),
                              status: Seq[Int] = Seq(),
                              reason: Seq[Int] = Seq(),
                              severity: Seq[Int] = Seq(),
                              isInternalAlarm: Option[Boolean],
                              pagination: Option[Pagination] = None,
                              alarmIds: Seq[Int] = Seq(),
                            ): Future[PaginatedResult[IncidentWithAlarmInfo]] = {

    val alarmsQuery = dynamicQuery[Alarm]
      .filterOpt(isInternalAlarm)((alarm, isInternalAlarm) => quote(alarm.isInternal == isInternalAlarm))
      .filterIf(severity.nonEmpty) { alarm =>
        liftQuery(severity).contains(alarm.severity)
      }
      .filterIf(alarmIds.nonEmpty) { alarm =>
        liftQuery(alarmIds).contains(alarm.id)
      }

    val incidentBySeverity = for {
      alarm <- alarmsQuery
      incident <- dynamicQuery[Incident].join(e => alarm.id == e.alarmId)
    } yield incident

    val incidentsQuery = incidentBySeverity
      .filterIf(icdIds.nonEmpty) { incident =>
        liftQuery(icdIds).contains(incident.icdId)
      }
      .filterIf(locationIds.nonEmpty) { incident =>
        liftQuery(locationIds).contains(incident.locationId)
      }
      .filterIf(reason.nonEmpty) { incident =>
        liftQuery(reason).contains(incident.reason)
      }
      .filterIf(status.nonEmpty) { incident =>
        liftQuery(status).contains(incident.status)
      }
      .filterOpt(accountId)((incident, accountId) => quote(incident.accountId == accountId))
      .filterOpt(groupId)((incident, groupId) => quote(incident.groupId.contains(groupId)))

    val finalQuery = createdAt.foldLeft(incidentsQuery) {
      case (acc, filter) => acc.filter(x => addLocalDateTimeFilter(x.createAt, filter))
    }

    val p = pagination.getOrElse(Pagination())
    val page = if(p.page < 1) 0 else p.page - 1
    val itemsToDrop = page * p.size
    val itemsToTake = p.size

    val items = Future {
      ctx.run(
        finalQuery
          .join(alarmsQuery).on(_.alarmId == _.id)
          .sortBy(_._1.createAt)(Ord.desc)
          .drop(itemsToDrop)
          .take(itemsToTake)
      )
    }

    val total = Future {
      ctx.run(finalQuery.size)
    }

    for {
      i <- items
      t <- total
    } yield PaginatedResult(i.map(x => IncidentWithAlarmInfo(x._1, x._2)), t)
  }

  private def addLocalDateTimeFilter(field: Quoted[LocalDateTime], filter: Filter[LocalDateTime]): Quoted[Boolean] = {
    // TODO: When we use the new method extensions see this to use just isAfter, isBefore, isEqual to cover all the cases
    // https://stackoverflow.com/questions/13936576/date-before-method-returns-false-if-both-dates-are-equal/13940015
    val value = filter.value

    filter.operator match {
      case "eq" => infix"($field = ${lift( value )})".as[Boolean]
      case "gte" => infix"($field >= ${lift( value )})".as[Boolean]
      case "gt" => infix"($field > ${lift( value )})".as[Boolean]
      case "lte" => infix"($field <= ${lift( value )})".as[Boolean]
      case "lt" => infix"($field < ${lift( value )})".as[Boolean]
      case _ => true
    }
  }

  def clearIncidentsByLocation(
                                locationId: UUID,
                                devices: List[DeviceSimple],
                                alarmIds: List[Int],
                                snoozeInSeconds: Int,
                                userId: Option[UUID] = None
                              ): Future[Long] = {

    val isSnooze = snoozeInSeconds > 0
    val snoozeTo = if(isSnooze) Some(LocalDateTime.now().plusSeconds(snoozeInSeconds)) else None
    val reason = if(isSnooze) IncidentReason.Snoozed else IncidentReason.Cleared
    val alarmsToClear = alarmIds ++ alarmIds.flatMap(alarmId => AlarmHelper.getAssociatedAlarmIds(alarmId))
    val updateAt = LocalDateTime.now()

    val triggeredIncidentsQuery = quote {
      query[Incident].filter { incident =>
        liftQuery(alarmsToClear).contains(incident.alarmId) &&
        lift(locationId) == incident.locationId &&
        lift(IncidentStatus.Triggered) == incident.status
      }
    }

    val clearQuery = quote {
      triggeredIncidentsQuery.update(
        _.status -> lift(IncidentStatus.Resolved),
        _.reason -> lift(Option(reason)),
        _.snoozeTo -> lift(snoozeTo),
        _.updateAt -> lift(updateAt)
      )
    }

    // Warning. Order of operations matter here!
    for {
      incidents            <- Future(ctx.run(triggeredIncidentsQuery.sortBy(_.updateAt)(Ord.desc)))
      clearedIncidentCount <- Future(ctx.run(clearQuery))
      _                    <- if (!isSnooze) deleteFilterState(incidents.map(_.id)) else Future.successful(())
    } yield {
      val eventualLocationDevices = retrieveDevicesByLocation(locationId)

      eventualLocationDevices.foreach { locationDevices =>
        refreshStatsCache(locationDevices)

        (devices.map(_.id) ++ locationDevices).distinct.foreach { icdId =>
          alarmIds.foreach { alarmId =>
            val incidentIds = incidents.map(_.id)
            cancelScheduledDeliveries(incidentIds, alarmId, icdId)
          }
        }
      }

      snoozeTo.foreach { snoozeValue =>
        alarmIds.foreach { alarmId =>
          createFilterState(FilterState(None, alarmId, Snooze, None, incidents.headOption.map(_.id), Some(locationId), userId, snoozeValue, None))
          devices.foreach(device => sendNotificationsResponse(device.macAddress, alarmId, snoozeValue))
        }
      }

      incidents.foreach { incident =>
        sendEntityActivityMessage(
          incident.copy(status = IncidentStatus.Resolved, reason = Option(reason), snoozeTo = snoozeTo, updateAt = updateAt)
        )
      }

      clearedIncidentCount
    }
  }

  def clearIncidentsByIcd(device: DeviceSimple, alarmIds: List[Int], snoozeInSeconds: Int,
                          reason: Option[Int] = None, userId: Option[UUID] = None): Future[Long] = {
    val isSnooze = snoozeInSeconds > 0
    val snoozeTo = if(isSnooze) Option(LocalDateTime.now().plusSeconds(snoozeInSeconds)) else None
    val clearReason = if (isSnooze) IncidentReason.Snoozed else reason.getOrElse(IncidentReason.Cleared)
    val alarmsToClear = alarmIds ++ alarmIds.flatMap(alarmId => AlarmHelper.getAssociatedAlarmIds(alarmId))
    val updateAt = LocalDateTime.now()

    val triggeredIncidentsQuery = quote {
      query[Incident].filter { incident =>
        liftQuery(alarmsToClear).contains(incident.alarmId) &&
        lift(device.id) == incident.icdId &&
        lift(IncidentStatus.Triggered) == incident.status
      }
    }

    val clearQuery = quote {
      triggeredIncidentsQuery.update(
        _.status -> lift(IncidentStatus.Resolved),
        _.reason -> lift(Option(clearReason)),
        _.snoozeTo -> lift(snoozeTo),
        _.updateAt -> lift(updateAt)
      )
    }

    // Warning. Order of operations matter here!
    for {
      incidents            <- Future(ctx.run(triggeredIncidentsQuery.sortBy(_.updateAt)(Ord.desc)))
      clearedIncidentCount <- Future(ctx.run(clearQuery))
      _                    <- if (!isSnooze) deleteFilterState(incidents.map(_.id)) else Future.successful(())
    } yield {
      snoozeTo.foreach { snoozeValue =>
        alarmIds.foreach { alarmId =>
          createFilterState(FilterState(None, alarmId, Snooze, Some(device.id), incidents.headOption.map(_.id), None, userId, snoozeValue, None))
          sendNotificationsResponse(device.macAddress, alarmId, snoozeValue)
        }
      }
      refreshStatsCache(Set(device.id))
      incidents.foreach { incident =>
        sendEntityActivityMessage(
          incident.copy(status = IncidentStatus.Resolved, reason = Option(clearReason), snoozeTo = snoozeTo, updateAt = updateAt)
        )
      }

      Future {
        alarmIds.foreach { alarmId =>
          val incidentIds = incidents.map(_.id)
          cancelScheduledDeliveries(incidentIds, alarmId, device.id)
        }
      }

      clearedIncidentCount
    }
  }

  def createIncidentSource(incidentSource: IncidentSource): Future[Unit] = {
    val insertQuery = quote {
      query[IncidentSource]
        .insert(lift(incidentSource))
        .onConflictIgnore
    }
    Future(ctx.run(insertQuery)).map(_ => ())
  }

  def upsertIncident(incident: Incident, userId: Option[UUID] = None): Future[Boolean] = {
    val eventualResolveQuery = if (incident.status == IncidentStatus.Triggered) {
      // Resolve all previous incidents in triggered state (should be just one - the latest)
      val incidentsToResolve = quote {
        query[Incident].filter { i =>
          lift(incident.alarmId) == i.alarmId &&
          lift(incident.icdId) == i.icdId &&
          lift(IncidentStatus.Triggered) == i.status &&
          lift(incident.updateAt) > i.updateAt
        }
      }

      val autoResolveQuery = quote {
        incidentsToResolve.update(
          _.status -> lift(IncidentStatus.Resolved),
          _.reason -> lift(Option(IncidentReason.UserMissed)),
          _.updateAt -> lift(incident.updateAt),
          _.newIncidentRef -> lift(Option(incident.id))
        )
      }

      Future(ctx.run(incidentsToResolve.sortBy(_.updateAt)(Ord.desc))).map { incidents =>
        ctx.run(autoResolveQuery)

        incidents.foreach { missedIncident =>
          sendEntityActivityMessage(
            missedIncident.copy(status = IncidentStatus.Resolved, reason = Option(IncidentReason.UserMissed), updateAt = incident.updateAt, newIncidentRef = Option(incident.id))
          )
        }

        incidents
      }
    } else Future.successful(Seq())


    val eventualResult = eventualResolveQuery.map { resolvedIncidents =>
      val incidentWithOldRef = resolvedIncidents.headOption.map { latestResolvedIncident =>
        incident.copy(oldIncidentRef = Some(latestResolvedIncident.id))
      }.getOrElse(incident)

      val upsertQuery = quote {
        query[Incident]
          .insert(lift(incidentWithOldRef))
          .onConflictUpdate(_.id)(
            (t, e) => t.status -> e.status,
            (t, e) => t.reason -> e.reason,
            (t, e) => t.updateAt -> e.updateAt,
            (t, e) => t.healthTestRoundId -> e.healthTestRoundId.map(_ => e.healthTestRoundId).getOrElse(t.healthTestRoundId),
            (t, e) => t.oldIncidentRef -> e.oldIncidentRef.map(_ => e.oldIncidentRef).getOrElse(t.oldIncidentRef)
          )
      }

      ctx.run(upsertQuery)
    }.map(_ => true)

    val eventualAlarm = getAlarm(incident.alarmId)

    eventualResult.foreach { _ =>
      refreshStatsCache(Set(incident.icdId))
      sendEntityActivityMessage(incident)

      if (incident.status != IncidentStatus.Received) {
        eventualAlarm.foreach { alarm =>
          sendAlertAckToDevice(incident, Severity.toString(alarm.map(_.severity).getOrElse(-1)))
        }
      }
    }

    eventualResult.map { r =>
      if (incident.status == IncidentStatus.Triggered) {
        eventualAlarm.foreach { maybeAlarm =>
          val maxDeliveryFreq = maybeAlarm.map(_.maxDeliveryFrequency).getOrElse("0 hours")
          val expiration = incident.updateAt.plus(JavaDuration.ofSeconds(ScalaDuration(maxDeliveryFreq).toSeconds))

          if (expiration.isAfter(LocalDateTime.now())) {
            createFilterState(
              FilterState(None, incident.alarmId, MaxFrequencyCap, Some(incident.icdId), Some(incident.id), Some(incident.locationId), userId, expiration, None)
            )
          }
        }
      }
      r
    }
  }

  // TODO: clearIncidentsByIcd has a similar logic. We may need to merge both methods into one.
  def resolvePendingIncidents(icdId: UUID, alarmIds: Set[Int], reason: Option[Int]): Future[Seq[Incident]] = {
    val associatedAlarmIds = alarmIds.flatMap(AlarmHelper.getAssociatedAlarmIds)
    val alarmsToResolve = alarmIds.union(associatedAlarmIds)
    val updateAt = LocalDateTime.now()

    val baseAlarmsQuery = quote {
      query[Incident].filter(incident => {
        lift(icdId) == incident.icdId &&
        lift(IncidentStatus.Triggered) == incident.status
      })
    }

    val pendingAlertsQuery = alarmsToResolve.headOption.map { _ =>
      quote {
        baseAlarmsQuery.filter { incident =>
          liftQuery(alarmsToResolve).contains(incident.alarmId)
        }
      }
    }.getOrElse(baseAlarmsQuery)

    val resolvePendingAlertsQuery = quote {
      pendingAlertsQuery.update(
        _.status -> lift(IncidentStatus.Resolved),
        _.reason -> lift(reason),
        _.updateAt -> lift(updateAt)
      )
    }

    // Warning. Order of operations matter here!
    for {
      incidents <- Future(ctx.run(pendingAlertsQuery))
      _         <- Future(ctx.run(resolvePendingAlertsQuery))
      _         <- deleteFilterState(incidents.map(_.id))
    } yield {
      refreshStatsCache(Set(icdId))
      incidents.foreach { incident =>
        val updatedIncident = incident.copy(status = IncidentStatus.Resolved, reason = reason, updateAt = updateAt)
        sendEntityActivityMessage(updatedIncident)


        getAlarm(incident.alarmId).foreach { alarm =>
          sendAlertAckToDevice(updatedIncident, Severity.toString(alarm.map(_.severity).getOrElse(-1)))
        }
      }
      alarmIds.foreach { alarmId =>
        val incidentIds = incidents.map(_.id)
        cancelScheduledDeliveries(incidentIds, alarmId, icdId)
      }
      incidents
    }
  }

  def getDeliverySettings(userId: UUID, icdId: UUID): Future[AlertDeliverySettings] = {
    this.getDeliverySettingsInBulk(userId, List(icdId), List())
  }

  private def getDefaultAlertSettings(deviceId: Option[UUID], locationId: Option[UUID], alarm: Alarm, systemSettings: AlarmSystemModeSettings): AlertSettings = {
    AlertSettings(
      deviceId,
      locationId,
      alarm.id,
      alarm.name,
      alarm.severity,
      systemSettings.systemMode,
      DeliverySettings(
        systemSettings.smsEnabled,
        systemSettings.emailEnabled,
        systemSettings.pushEnabled,
        systemSettings.callEnabled
      ),
      isMuted = false
    )
  }

  def getGroupRoleDeliverySettings(groupId: UUID, role: String): Future[List[GroupRoleAlertSettings]] = {
    //Get user settings, if there is no settings for the group/role pair, get defaults from Alarm delivery settings
    val result = quote {
      for {
        a <- query[Alarm].filter(x => !x.isInternal)
        s <- query[AlarmSystemModeSettings].join(s => a.id == s.alarmId && s.accountType == lift(DefaultAccountType))
        u <- query[GroupRoleDeliverySettings].leftJoin(u => s.id == u.alarmSystemModeSettingsId && u.groupId == lift(groupId) && u.role == lift(role))
      } yield (a, s, u)
    }

    Future(ctx.run(result)).map(items => {
      items.flatMap {
        case (alarm, systemSettings, Some(groupRoleSettings)) => {
          List(
            GroupRoleAlertSettings(
              groupRoleSettings.groupId,
              groupRoleSettings.role,
              alarm.id,
              alarm.name,
              alarm.severity,
              systemSettings.systemMode,
              groupRoleSettings.settings
            )
          )
        }
        case (alarm, systemSettings, None) => {
          List(
            GroupRoleAlertSettings(
              groupId,
              role,
              alarm.id,
              alarm.name,
              alarm.severity,
              systemSettings.systemMode,
              DeliverySettings(
                systemSettings.smsEnabled, systemSettings.emailEnabled, systemSettings.pushEnabled, systemSettings.callEnabled
              )
            )
          )
        }
      }
    })
  }

  def getDeliverySettingsInBulk(userId: UUID, deviceIds: List[UUID], locationIds: List[UUID], accountType: String = DefaultAccountType): Future[AlertDeliverySettings] = {
    //Get user settings, if there is no settings for the user, get defaults from Alarm delivery settings
    val safeDeviceIds = deviceIds.headOption.fold(List(nilUuid))(_ => deviceIds)
    val safeLocationIds = locationIds.headOption.fold(List(nilUuid))(_ => locationIds)
    val result = quote {
      for {
        a <- query[Alarm].filter(x => !x.isInternal)
        s <- query[AlarmSystemModeSettings].join(s => a.id == s.alarmId && s.accountType == lift(accountType))
        u <- query[UserDeliverySettings].leftJoin { u =>
                s.id == u.alarmSystemModeSettingsId &&
                  u.userId == lift(userId) &&
                  liftQuery(safeDeviceIds).contains(u.icdId) &&
                  liftQuery(safeLocationIds).contains(u.locationId)
              }
      } yield (a, s, u)
    }

    Future(ctx.run(result)).map(items => {
      val systemSettings = items.map { case (_, systemModeSettings, _) =>
        systemModeSettings.id -> systemModeSettings
      }.toMap

      val alarmsMap = items.map { case (alarm, _, _) =>
        alarm.id -> alarm
      }.toMap

      val userSettings = items.flatMap { case (_, _, maybeUserSettings) => maybeUserSettings }

      val parentChildrenAlarmMap = alarmsMap.values.foldLeft(Map[Int, Seq[Alarm]]()) { case (acc, alarm) =>
        alarm.parentId.fold(acc) { parentId =>
          acc + (parentId -> (acc.getOrElse(parentId, Seq()) :+ alarm))
        }
      }

      val userAlertSettings = userSettings.flatMap { s =>
        val alarmSysSettings = systemSettings(s.alarmSystemModeSettingsId)
        val alarm = alarmsMap(alarmSysSettings.alarmId)
        val userDefinedSettingsTuple = Seq(p"${alarm.id}.${alarmSysSettings.systemMode}.${s.locationId}.${s.icdId}" ->
          AlertSettings(s.icdId, s.locationId, alarm.id, alarm.name, alarm.severity, alarmSysSettings.systemMode, s.settings, s.isMuted))

        parentChildrenAlarmMap.get(alarm.id).fold(userDefinedSettingsTuple) { childrenAlarms =>
          userDefinedSettingsTuple ++ childrenAlarms.map { childAlarm =>
            p"${childAlarm.id}.${alarmSysSettings.systemMode}.${s.locationId}.${s.icdId}" ->
              AlertSettings(s.icdId, s.locationId, childAlarm.id, childAlarm.name, childAlarm.severity, alarmSysSettings.systemMode, s.settings, s.isMuted)
          }
        }
      }.toMap

      val userNonDefinedSettings = systemSettings.values.flatMap { s =>
        val alarm = alarmsMap(s.alarmId)
        val byDeviceSettings = deviceIds
          .withFilter(deviceId => !userAlertSettings.isDefinedAt(p"${alarm.id}.${s.systemMode}.$nilUuid.$deviceId"))
          .map(deviceId => getDefaultAlertSettings(Some(deviceId), None, alarm, systemSettings(s.id)))
        val byLocationSettings = locationIds
          .withFilter(locationId => !userAlertSettings.isDefinedAt(p"${alarm.id}.${s.systemMode}.$locationId.$nilUuid"))
          .map(locationId => getDefaultAlertSettings(None, Some(locationId), alarm, systemSettings(s.id)))
        byDeviceSettings ++ byLocationSettings
      }

      AlertDeliverySettings(userAlertSettings.values.toList, userNonDefinedSettings.toList)
    })
  }

  def saveDeliverySettings(
                            userId: UUID,
                            settings: List[AlarmDeliverySettings],
                            accountType: String = DefaultAccountType
                          ): Future[Boolean] = {

    getAllAlarmSystemModeSettings(accountType).flatMap(allSettings => {

      val defaultSettingsMap = allSettings.map(s => AlarmSystemModeKey(s.alarmId, s.systemMode) -> s).toMap
      val validSettings = settings
        .withFilter(s => defaultSettingsMap.contains(AlarmSystemModeKey(s.alarmId, s.systemMode)))
        .map { s =>
          // Hack to prevent insertion to fail.
          s
            .modify(_.deviceId).setToIf(s.deviceId.isEmpty)(Some(nilUuid))
            .modify(_.locationId).setToIf(s.locationId.isEmpty)(Some(nilUuid))
        }
      val newSettings = mergeNewSettings(defaultSettingsMap, validSettings)

      val result = quote {
        liftQuery(newSettings).foreach { it =>
          query[UserDeliverySettings]
            .insert(
              _.userId                    -> lift(userId),
              _.icdId                     -> it._2.deviceId.getOrElse(lift(nilUuid)),
              _.locationId                -> it._2.locationId.getOrElse(lift(nilUuid)),
              _.alarmSystemModeSettingsId -> it._1,
              _.settings.callEnabled      -> it._2.settings.callEnabled,
              _.settings.emailEnabled     -> it._2.settings.emailEnabled,
              _.settings.pushEnabled      -> it._2.settings.pushEnabled,
              _.settings.smsEnabled       -> it._2.settings.smsEnabled,
              _.isMuted                   -> it._2.isMuted)
            .onConflictUpdate(_.userId, _.icdId, _.locationId, _.alarmSystemModeSettingsId)(
              (t, e) => t.settings.smsEnabled   -> e.settings.smsEnabled,
              (t, e) => t.settings.pushEnabled  -> e.settings.pushEnabled,
              (t, e) => t.settings.callEnabled  -> e.settings.callEnabled,
              (t, e) => t.settings.emailEnabled -> e.settings.emailEnabled,
              (t, e) => t.isMuted               -> e.isMuted
            )
        }
      }
      Future(ctx.run(result)).map(_ => true)
    })
  }

  def deleteDeliverySettingsByDeviceId(deviceId: UUID): Future[Unit] = {
    val deleteQuery = quote {
      query[UserDeliverySettings]
        .filter(_.icdId == lift(deviceId))
        .delete
    }
    Future(ctx.run(deleteQuery))
  }

  def getAlarmSystemModeSettings(alarmId: Int, accountType: String = DefaultAccountType): Future[List[AlarmSystemModeSettings]] = {
    val result = quote {
      query[AlarmSystemModeSettings]
        .filter { s =>
          s.alarmId == lift(alarmId) &&
          s.accountType == lift(accountType)
        }
    }
    Future(ctx.run(result))
  }

  def getAllAlarmSystemModeSettings(accountType: String = DefaultAccountType): Future[List[AlarmSystemModeSettings]] = {
    val result = quote {
      query[AlarmSystemModeSettings]
        .filter(_.accountType == lift(accountType))
    }
    Future(ctx.run(result))
  }

  def getUserAlarmSettings(userId: UUID, deviceIds: Seq[UUID]): Future[List[UserAlarmSettings]] = {
    val userAlarmSettingsQuery = quote {
      query[UserAlarmSettings]
        .filter { s =>
          lift(userId) == s.userId &&
          liftQuery(deviceIds).contains(s.icdId)
        }
    }

    Future(ctx.run(userAlarmSettingsQuery)).map { settings =>
      val settingsNotFound = deviceIds
        .diff(settings.map(_.icdId))
        .map(UserAlarmSettings.buildDefault(userId, _))

      settings ++ settingsNotFound
    }
  }

  def saveUserAlarmSettings(userAlarmSettings: List[UserAlarmSettings]): Future[Unit] = {
    val userIds = userAlarmSettings.map(_.userId).distinct
    val deviceIds = userAlarmSettings.map(_.icdId).distinct

    val oldSettingsQuery = quote { (userIds: Query[UUID], deviceIds: Query[UUID]) =>
      query[UserAlarmSettings].filter(x => userIds.contains(x.userId) && deviceIds.contains(x.icdId))
    }

    val oldSettingsMap = ctx
      .run(oldSettingsQuery(liftQuery(userIds), liftQuery(deviceIds)))
      .map(x => (x.userId, x.icdId) -> x).toMap

    val newSettings = userAlarmSettings
      .map(x => UserAlarmSettings.merge(x, oldSettingsMap.getOrElse((x.userId, x.icdId), x)))

    val upsertQuery = quote {
      liftQuery(newSettings).foreach { s =>
        query[UserAlarmSettings]
          .insert(
            _.userId -> s.userId,
            _.icdId -> s.icdId,
            _.floSenseLevel -> s.floSenseLevel,
            _.smallDripSensitivity -> s.smallDripSensitivity
          )
          .onConflictUpdate(_.userId, _.icdId)(
            (t, e) => t.floSenseLevel -> e.floSenseLevel,
            (t, e) => t.smallDripSensitivity -> e.smallDripSensitivity
          )
      }
    }

    Future(ctx.run(upsertQuery)).map(_ => ())
  }

  def deleteUserAlarmSettingsByDeviceId(deviceId: UUID): Future[Unit] = {
    val deleteQuery = quote {
      query[UserAlarmSettings]
        .filter(_.icdId == lift(deviceId))
        .delete
    }
    Future(ctx.run(deleteQuery))
  }

  private def cancelScheduledDeliveries(incidentIds: Seq[UUID], alarmId: Int, icdId: UUID): Future[Unit] = {
    // TODO: Optimize to cancel scheduled deliveries. We need to know what were sent directly and what were sent using task scheduler.
    val userIdsQuery = quote {
      val userIds = for {
        d <- query[DeliveryEvent] if liftQuery(incidentIds).contains(d.alarmEventId)
      } yield {
        d.userId
      }
      userIds.distinct
    }

    Future(ctx.run(userIdsQuery)).map { userIds =>
      userIds.foreach { userId =>
        incidentIds.foreach { incidentId =>
          cancelScheduledTask(DeliveryEventMedium.VoiceCall, userId, icdId, alarmId, incidentId)
          cancelScheduledTask(DeliveryEventMedium.PushNotification, userId, icdId, alarmId, incidentId)
          cancelScheduledTask(DeliveryEventMedium.Sms, userId, icdId, alarmId, incidentId)
          cancelScheduledTask(DeliveryEventMedium.Email, userId, icdId, alarmId, incidentId)
        }
      }
    }
  }

  private def cancelScheduledTask(deliveryMedium: Int, userId: UUID, icdId: UUID, alarmId: Int, incidentId: UUID): Future[Unit] = {
    val id = p"${DeliveryEventMedium.toString(deliveryMedium)}-$alarmId-$userId-$icdId-$incidentId"
    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = p"http://flo-task-scheduler-v2.flo-task-scheduler-v2.svc.cluster.local/tasks/$id/cancel" // TODO: Configurable!
    )
    RetrySupport
      .retry[HttpResponse](
        attempt = () => {
          Http()(as)
            .singleRequest(httpRequest)
            .map {
              case r if r.status.isSuccess() => r
              case r if r.status.intValue() == 404 => r // No failure / No retry. Task was never created.
              case r =>
                throw new Exception(p"Error while canceling task $id - status: ${r.status.value} - body: ${Unmarshaller
                  .stringUnmarshaller(r.entity)(ex, am)}")
            }(ex)
        },
        attempts = 3,
        delay = 1.seconds
      )(ex, as.scheduler)
      .map(_ => ())(ex)
  }

  private def sendEntityActivityMessage(incident: Incident): Future[Unit] = {
    if (incident.status == IncidentStatus.Triggered || incident.status == IncidentStatus.Resolved) {
      val eventualAlarm = getAlarm(incident.alarmId)
      val eventualDeliveryEvents = getDeliveryEvents(Set(incident.id))
      val eventualMacAddress = retrieveMacAddressByDeviceId(incident.icdId.toString)

      for {
        alarm <- eventualAlarm
        deliveryEvents <- eventualDeliveryEvents
        maybeMacAddress <- eventualMacAddress
      } yield {
        entityActivityTopic.fold(Future.unit) { topic =>
          kafkaProducer.send[EntityActivity](
            topic,
            EntityActivity(
              date = LocalDateTime.now(),
              `type` = "alert",
              action = if (incident.status == IncidentStatus.Triggered) "created" else "updated",
              id = incident.id,
              item = EntityActivityItem.build(incident, deliveryEvents.getOrElse(incident.id, Seq.empty), alarm, maybeMacAddress.getOrElse(""))

            ),
            entityActivity => Serialization.write(entityActivity)
          ).map(_ => ())
        }
      }
    } else {
      Future.unit
    }
  }

  private def mergeNewSettings(
                                defaultSettingsMap: Map[AlarmSystemModeKey, AlarmSystemModeSettings],
                                settingsList: List[AlarmDeliverySettings]): List[(AlarmSystemModeSettingsId, AlarmDeliverySettings)] = {

    def mergeIfShouldExist(maybeDefault: Option[Boolean], newValue: Option[Boolean]): Option[Boolean] =
      maybeDefault.map(default => newValue.getOrElse(default))

    settingsList.map(s => {
      val defaultSettings = defaultSettingsMap(AlarmSystemModeKey(s.alarmId, s.systemMode))

      val newSettings = s.copy(
        settings = DeliverySettings(
          mergeIfShouldExist(defaultSettings.smsEnabled, s.settings.smsEnabled),
          mergeIfShouldExist(defaultSettings.emailEnabled, s.settings.emailEnabled),
          mergeIfShouldExist(defaultSettings.pushEnabled, s.settings.pushEnabled),
          mergeIfShouldExist(defaultSettings.callEnabled, s.settings.callEnabled)
        )
      )

      (defaultSettings.id, newSettings)
    })
  }

  def generateRandomIncidents(userId: UUID, icdId: UUID, locationId: UUID): Future[Boolean] = {
    val systemModes = Array(SystemMode.Away, SystemMode.Home)
    val statuses = Array(IncidentStatus.Triggered, IncidentStatus.Resolved)

    import scala.util.Random

    // Generate 3 critical incidents in received state
    // Generate 3 warning incidents in received state
    // Generate 3 info incidents in resolved state
    val alarmsFeature = for {
      critical <- getAlarmsBySeverity(Severity.Critical, 3)
      warning <- getAlarmsBySeverity(Severity.Warning, 3)
      info <- getAlarmsBySeverity(Severity.Info, 3)
    } yield critical ++ warning ++ info

    val dataValues = Map("efd" -> 3, "fr" -> 0)
    val randomIncidents = random[Incident](9)

    alarmsFeature.flatMap(alarms => {
      val incidents = alarms.zipWithIndex.map {
        case (alarm, index) => {
          val randomSystemMode = Random.shuffle(systemModes.toList).head
          val randomStatus = Random.shuffle(statuses.toList).head

          val ev = randomIncidents(index).copy(alarmId = alarm.id, icdId = icdId, locationId = locationId, dataValues = dataValues)

          ev.copy(status = randomStatus, systemMode = randomSystemMode)
        }
      }
      val result = quote {
        liftQuery(incidents).foreach(e => query[Incident].insert(e))
      }
      Future(ctx.run(result)).map(_ => true)
    })
  }

  private def getAlarmsBySeverity(severity: Int, limit: Int): Future[List[AlarmModel]] = {
    val alarmsQuery = quote {
      query[Alarm].filter(_.severity == lift(severity)).take(lift(limit))
    }

    val eventualParentChildren = getParentChildrenAlarms
    val eventualAlarms = Future(ctx.run(alarmsQuery))

    for {
      parentChildren <- eventualParentChildren
      alarms <- eventualAlarms
    } yield {
      alarms.map(_.toModel(parentChildren))
    }
  }

  def getAlertActionsAndSupportOptions: Future[List[ActionSupport]] = {
    val result = quote {
      for {
        l <- query[Alarm]
        r <- query[AlarmToAction].leftJoin(r => r.alarmId == l.id)
        a <- query[ActionModel].leftJoin(a => r.getOrNull.actionId == a.id)
        s <- query[SupportOption].leftJoin(s => s.alarmId == l.id)
      } yield (l, r, a, s)
    }

    Future(ctx.run(result)).map(items => {
      val grouped = items.groupBy { case (alarm, _, _, _) => alarm.id }
      grouped.map { case (k, v) => ActionSupport(
        k,
        v.flatMap { case (_, _, action, _) => action }.distinct.sortBy(_.sort),
        v.flatMap { case (_, _, _, supportOption) => supportOption }.distinct
      )}.to[List]
    })
  }

  def getAlarm(id: Int): Future[Option[AlarmModel]] = {
    alarmCache.getIfPresent(id) match {
      case Some(alarm) => Future.successful(Some(alarm))

      case None =>
        val alarmQuery = quote {
          query[Alarm].filter(_.id == lift(id))
        }

        val eventualParentChildren = getParentChildrenAlarms
        val eventualAlarm = Future(ctx.run(alarmQuery))

        eventualParentChildren.flatMap { parentChildren =>
          eventualAlarm.map { alarm =>
            alarm.headOption.map(x => {
              val alarmModel = x.toModel(parentChildren)

              alarmCache.put(id, alarmModel)
              alarmModel
            })
          }
        }
    }
  }

  def getDeliveryMediumTemplate(alarmId: Int, deliveryMediumId: Int): Future[Option[DeliveryMediumTemplate]] = {
    val result = quote {
      query[DeliveryMediumTemplate]
        .filter(x => x.alarmId == lift(alarmId) && x.deliveryMediumId == lift(deliveryMediumId))
    }

    Future(ctx.run(result)).map(_.headOption)
  }

  def registerDeliveryMediumTriggered(incidentId: UUID, medium: Int, userId: UUID): Future[Boolean] = {
    val event = DeliveryEvent(
      UUID.randomUUID(),
      incidentId,
      "not-found",
      medium,
      DeliveryMediumStatus.Queued,
      Map(),
      userId,
      LocalDateTime.now(),
      LocalDateTime.now()
    )

    val result = quote {
      query[DeliveryEvent].insert(lift(event))
    }
    Future(ctx.run(result)).map(_ => true)
  }

  def upsertDeliveryEvent(deliveryEvent: DeliveryEvent): Future[Unit] = {
    val upsertQuery = quote {
      query[DeliveryEvent]
        .insert(lift(deliveryEvent))
        .onConflictUpdate(_.id)(
          (t, e) => t.updateAt -> e.updateAt,
          (t, e) => t.info -> infix"(${t.info}::jsonb || ${e.info}::jsonb)".as[Map[String, Any]],
          (t, e) => t.status -> e.status,
          (t, e) => t.externalId -> e.externalId
        )
    }

    Future(ctx.run(upsertQuery)).map(_ => ())
  }

  def getDeliveryEvents(incidentIds: Set[UUID]): Future[Map[UUID, Seq[DeliveryEvent]]] = {
    Future {
      ctx.run(quote {
        query[DeliveryEvent]
          .filter { deliveryEvent =>
            liftQuery(incidentIds).contains(deliveryEvent.alarmEventId)
          }
      })
    }.map { deliveryEvents =>
      deliveryEvents.groupBy(_.alarmEventId)
    }
  }

  def getDeliveryEvent(externalId: String): Future[Option[DeliveryEvent]] = {
    val deliveryEventsQuery = quote {
      query[DeliveryEvent]
        .filter(deliveryEvent => deliveryEvent.externalId == lift(externalId))
        .take(1)
    }

    Future {
      ctx.run(deliveryEventsQuery)
    }.map(_.headOption)
  }

  def getDeliveryEvent(alarmEventId: UUID, userId: UUID, medium: Int): Future[Option[DeliveryEvent]] = {
    val deliveryEventsQuery = quote {
      query[DeliveryEvent]
        .filter { deliveryEvent =>
          deliveryEvent.alarmEventId == lift(alarmEventId) &&
          deliveryEvent.userId == lift(userId) &&
          deliveryEvent.medium == lift(medium)
        }
        .take(1)
    }

    Future {
      ctx.run(deliveryEventsQuery)
    }.map(_.headOption)
  }

  def updateDeliveryEvent(externalId: String, eventStatus: Int, metadata: Map[String, Any]): Future[Unit] = {
    getDeliveryEvent(externalId).flatMap {
      case Some(deliveryEvent) => {
        upsertDeliveryEvent(deliveryEvent.copy(status = eventStatus, info = metadata))
      }
      case None => Future.unit
    }
  }

  def updateDeliveryEvent(
                            incidentId: UUID,
                            userId: UUID,
                            medium: Int,
                            externalId: String,
                            eventStatus: Int,
                            metadata: Map[String, Any]
                          ): Future[Unit] = {
    getDeliveryEvent(incidentId, userId, medium).flatMap {
      case Some(deliveryEvent) => {
        upsertDeliveryEvent(deliveryEvent.copy(externalId = externalId, status = eventStatus, info = metadata))
      }
      case None => Future.unit
    }
  }

  def retrieveStatistics(filter: StatisticsFilter, byPassCache: Boolean = false): Future[Statistics] = {
    if (byPassCache || filter.accountId.isDefined || filter.from.isDefined || filter.to.isDefined || filter.groupId.isDefined) {
      val baseQuery = quote {
        query[Incident]
          .filter(_.status == lift(IncidentStatus.Triggered))
          .join(query[Alarm]).on(_.alarmId == _.id)
      }

      val dynamicQuery = baseQuery.dynamic
      val finalQuery = applyFilters(filter, dynamicQuery)

      Future(ctx.run(finalQuery)).map(items => {
        val deviceStats = items
          .groupBy(_._1.icdId)
          .map {
            case (_, stats) =>
              val statMap = stats.groupBy(_._2.severity)
              val infoCount = statMap.get(Severity.Info).fold(0)(_.size)
              val warningCount = statMap.get(Severity.Warning).fold(0)(_.size)
              val criticalCount = statMap.get(Severity.Critical).fold(0)(_.size)

              val deviceInfoCount = Math.min(1, infoCount)
              val deviceWarningCount = Math.min(1, warningCount)
              val deviceCriticalCount = Math.min(1, criticalCount)

              val deviceInfoAbsoluteCount = if (deviceWarningCount > 0) 0 else deviceInfoCount
              val deviceWarningAbsoluteCount = if (deviceCriticalCount > 0) 0 else deviceWarningCount

              val alarmStats = stats
                .groupBy(_._2.id)
                .map {
                  case (alarmId, incidents) => alarmId -> incidents.size.toLong
                }

              Statistics(
                info = Stat(infoCount, DeviceStat(deviceInfoCount, deviceInfoAbsoluteCount)),
                warning = Stat(warningCount, DeviceStat(deviceWarningCount, deviceWarningAbsoluteCount)),
                critical = Stat(criticalCount, DeviceStat(deviceCriticalCount, deviceCriticalCount)),
                alarmCount = alarmStats
              )
          }

        deviceStats.foldLeft(Statistics(Stat.empty, Stat.empty, Stat.empty, Map())) { (result, stats) =>
          result.copy(
            info = sumStats(result.info, stats.info),
            warning = sumStats(result.warning, stats.warning),
            critical = sumStats(result.critical, stats.critical),
            alarmCount = mergeMaps(result.alarmCount, stats.alarmCount)
          )
        }
      })

    } else {

      val eventualDevices = {
        filter.locationId
          .map(retrieveDevicesByLocation)
          .getOrElse {
            Future.successful {
              filter.icdId
                .map(Set(_))
                .getOrElse(Set())
            }
          }
      }

      eventualDevices.flatMap(retrieveDeviceStats)
    }
  }

  def retrieveStatistics(filter: BatchStatisticsFilter): Future[Statistics] = {
    val filterDevices = filter.deviceIds.getOrElse(Set())
    val eventualDevices = {
      filter.locationIds
        .map(locationIds => Future.traverse(locationIds)(retrieveDevicesByLocation).map(_.flatten ++ filterDevices))
        .getOrElse(Future.successful(filterDevices))
    }
    eventualDevices.flatMap(retrieveDeviceStats)
  }

  def retrieveAlertFeedbackFlows(): Future[Seq[AlertFeedbackFlow]] = {
    val retrieveAlertFeedbackFlowsQuery = quote {
      query[AlertFeedbackFlow]
    }

    Future {
      ctx.run(retrieveAlertFeedbackFlowsQuery)
    }
  }

  def retrieveAlertFeedbackFlows(alarmId: Int): Future[Seq[AlertFeedbackFlow]] = {
    val retrieveAlertFeedbackFlowsQuery = quote {
      query[AlertFeedbackFlow]
        .filter { alertFeedbackFlow =>
          alertFeedbackFlow.alarmId == lift(alarmId)
        }
    }

    Future {
      ctx.run(retrieveAlertFeedbackFlowsQuery)
    }
  }

  def retrieveUserFeedbackOptions(alarmId: Int): Future[Option[UserFeedbackOptions]] = {
    val retrieveUserFeedbackOptionsQuery = quote {
      for {
        a <- query[Alarm] if a.id == lift(alarmId)
        ufo <- query[UserFeedbackOptions] if a.userFeedbackOptionsId == Option(ufo.id)
      } yield (a, ufo)
    }

    Future(ctx.run(retrieveUserFeedbackOptionsQuery)).map(_.headOption.map(_._2))
  }

  def retrieveUserFeedbackOptions(): Future[Seq[UserFeedbackOptions]] = {
    val retrieveUserFeedbackOptionsQuery = quote {
      query[UserFeedbackOptions]
    }

    Future(ctx.run(retrieveUserFeedbackOptionsQuery))
  }

  def retrieveUserFeedback(incidentIds: Set[UUID]): Future[Seq[UserFeedback]] = {
    val userFeedbackQuery = quote {
      query[UserFeedback]
        .filter { userFeedback =>
          liftQuery(incidentIds).contains(userFeedback.incidentId)
        }
    }

    Future(ctx.run(userFeedbackQuery))
  }

  private def applyFilters(filter: StatisticsFilter, query: DynamicQuery[(Incident, Alarm)]): DynamicQuery[(Incident, Alarm)] = {
    query
      .filterOpt(filter.icdId)((incident, icdId) => quote(incident._1.icdId == icdId))
      .filterOpt(filter.locationId)((incident, locationId) => quote(incident._1.locationId == locationId))
      .filterOpt(filter.accountId)((incident, accountId) => quote(incident._1.accountId == accountId))
      .filterOpt(filter.from)((incident, from) => quote(incident._1.updateAt > from))
      .filterOpt(filter.to)((incident, to) => quote(incident._1.updateAt < to))
      .filterOpt(filter.groupId)((incident, groupId) => quote(incident._1.groupId.contains(groupId)))
  }

  def getUserGraveyardTime(userId: UUID): Future[Option[UserGraveyardTime]] = {
    val result = quote {
      query[UserGraveyardTime]
        .filter(_.userId == lift(userId))
        .take(1)
    }
    Future(ctx.run(result)).map(_.headOption)
  }

  def retrieveMacAddressByDeviceId(deviceId: String): Future[Option[String]] = {
    val lookupKey = deviceIdToMacAddressLookupKey(deviceId)

    redis.get[String](lookupKey).flatMap {

      case None =>
        device.get(deviceId, Seq()).map { maybeDevice =>
          maybeDevice.map { device =>
            val thirtyDays = JavaDuration.of(30, ChronoUnit.DAYS).getSeconds
            redis.set(lookupKey, device.macAddress, Some(thirtyDays))

            device.macAddress
          }
        }

      case macAddress @ Some(_) => Future.successful(macAddress)
    }
  }

  def createVoiceRequestLog(voiceRequestLog: VoiceRequestLog): Future[Unit] = {
    val insertQuery = quote {
      query[VoiceRequestLog]
        .insert(lift(voiceRequestLog))
        .onConflictUpdate(_.incidentId)(
          (t, e) => t.requestBody -> e.requestBody
        )
    }
    Future(ctx.run(insertQuery))
  }

  def deleteFilterState(id: UUID): Future[Boolean] = {
    val deleteQuery = quote {
      query[FilterState]
        .filter(_.id == lift(Option(id)))
        .delete
    }
    Future(ctx.run(deleteQuery)).map(count => count > 0)
  }

  def deleteFilterState(incidentIds: Seq[UUID]): Future[Unit] = {
    val deleteQuery = quote {
      query[FilterState]
        .filter(fs => liftQuery(incidentIds).contains(fs.incidentId))
        .delete
    }
    Future(ctx.run(deleteQuery))
  }

  def deleteFilterStateByDeviceId(deviceId: UUID): Future[Unit] = {
    val deleteQuery = quote {
      query[FilterState]
        .filter(_.deviceId == lift(Option(deviceId)))
        .delete
    }
    Future(ctx.run(deleteQuery))
  }

  def createFilterState(filterState: FilterState): Future[FilterState] = {
    val insertQuery = quote {
      query[FilterState]
        .insert(
          _.id -> lift(Option(filterState.id.getOrElse(UUID.randomUUID()))),
          _.`type` -> lift(filterState.`type`),
          _.alarmId -> lift(filterState.alarmId),
          _.expiration -> lift(filterState.expiration),
          _.deviceId -> lift(Option(filterState.deviceId.getOrElse(nilUuid))),
          _.locationId -> lift(Option(filterState.locationId.getOrElse(nilUuid))),
          _.incidentId -> lift(Option(filterState.incidentId.getOrElse(nilUuid))),
          _.userId -> lift(Option(filterState.userId.getOrElse(nilUuid))),
          _.createdAt -> lift(Option(filterState.createdAt.getOrElse(LocalDateTime.now())))
        )
        .onConflictUpdate(_.alarmId, _.`type`, _.deviceId, _.locationId, _.userId)(
          (t, e) => t.expiration -> e.expiration,
          (t, e) => t.incidentId -> e.incidentId,
          (t, e) => t.createdAt -> e.createdAt
        ).returning { f =>
        FilterState(f.id, f.alarmId, f.`type`, f.deviceId, f.incidentId, f.locationId, f.userId, f.expiration, f.createdAt)
      }
    }

    Future(ctx.run(insertQuery)).map(cleanUpFilterState)
  }

  def getFilterState(id: UUID): Future[Option[FilterState]] = {
    val filterStateQuery = quote {
      query[FilterState]
        .filter(_.id == lift(Option(id)))
    }
    Future(ctx.run(filterStateQuery)).map(_.headOption.map(cleanUpFilterState))
  }

  def getFilterStateByDeviceId(deviceId: UUID): Future[Seq[FilterState]] = {

    val filterStateQuery = quote {
      query[FilterState]
        .filter(_.deviceId == lift(Option(deviceId)))
    }
    Future(ctx.run(filterStateQuery)).map(_.map(cleanUpFilterState))
  }

  def getFrequencyCapExpiration(alarmId: Int, deviceId: UUID, userId: UUID): Future[Option[LocalDateTime]] = {
    val filterStateQuery = quote {
      query[FilterState]
        .filter { filterState =>
          filterState.alarmId == lift(alarmId) &&
            filterState.`type` == lift(MaxFrequencyCap: FilterStateType) &&
            filterState.expiration > lift(LocalDateTime.now()) &&
            filterState.deviceId.contains(lift(deviceId)) &&
            filterState.userId.contains(lift(userId))
        }
        .sortBy { fs =>
          (fs.deviceId.contains(lift(deviceId)), fs.expiration)
        } (Ord(Ord.desc, Ord.asc))
    }
    Future(ctx.run(filterStateQuery)).map(_.headOption.map(cleanUpFilterState(_).expiration))
  }

  def getSnoozeTime(alarmId: Int, deviceId: UUID, locationId: UUID, userId: UUID): Future[Option[LocalDateTime]] = {
    getExpirationFromFilter(Snooze, alarmId, deviceId, locationId, userId)
  }

  def createIncidentText(incidentText: IncidentText): Future[Unit] = {
    val insertQuery = quote {
      query[IncidentText]
        .insert(lift(incidentText))
        .onConflictIgnore
    }
    Future(ctx.run(insertQuery)).map(_ => ())
  }

  def getIncidentTexts(incidentIds: Set[UUID], lang: String, unitSystem: String, fallbackLang: Option[String] = Some("en-us")): Future[Seq[IncidentText]] = {
    val insertQuery = quote {
      query[IncidentText]
        .filter { incidentText =>
          liftQuery(incidentIds).contains(incidentText.incidentId)
        }
    }

    Future(ctx.run(insertQuery)).map { incidentTexts =>
      incidentTexts.map { incidentText =>
        incidentText
          .modify(_.text)
          .setTo(incidentText.text.foldLeft(Map[String, Set[LocalizedText]]()) { case (acc, (key, localizedTexts)) =>
            acc.updated(key, {
              val textsFilteredUnitSystem = localizedTexts.filter(_.unitSystems.contains(unitSystem))
              val filteredEq = textsFilteredUnitSystem.filter(_.lang.contains(lang))
              filteredEq.headOption.map(_ => filteredEq).getOrElse {
                if (lang.length > 2) {
                  val filteredPartialMatch = textsFilteredUnitSystem.filter {_.lang.exists(l => l.length == 2 && lang.startsWith(l))}
                  filteredPartialMatch.headOption.map(_ => filteredPartialMatch).getOrElse {
                    fallbackLang.fold(textsFilteredUnitSystem)(fallback => textsFilteredUnitSystem.filter(_.lang.contains(fallback)))
                  }
                } else {
                  fallbackLang.fold(textsFilteredUnitSystem)(fallback => textsFilteredUnitSystem.filter(_.lang.contains(fallback)))
                }
              }
            })
          })
      }
    }
  }

  def saveUserFeedback(userFeedback: UserFeedback, force: Boolean): Future[Boolean] = {
    retrieveUserFeedback(Set(userFeedback.incidentId)).flatMap { maybeExistingFeedback =>
      val isSameUser = maybeExistingFeedback.headOption.exists(_.userId == userFeedback.userId)

      val baseQuery = quote {
        query[UserFeedback]
          .insert(lift(userFeedback))
      }

      val insertQuery = if (force || isSameUser) {
        quote {
          baseQuery
            .onConflictUpdate(_.incidentId)(
              (t, e) => t.userId -> e.userId,
              (t, e) => t.feedback -> e.feedback,
              (t, e) => t.updatedAt -> e.updatedAt
            )
        }
      } else baseQuery

      Future(ctx.run(insertQuery))
        .map(_ => true)
        .recover { case _ => false }
    }
  }

  def moveIncidents(deviceId: UUID, srcAccountId: UUID, destAccountId: UUID, srcLocationId: UUID, destLocationId: UUID): Future[Unit] = {
    val updateQuery = quote {
      query[Incident]
        .filter { i =>
          i.accountId == lift(srcAccountId) &&
            i.locationId == lift(srcLocationId) &&
            i.icdId == lift(deviceId)
        }
        .update(
          _.accountId -> lift(destAccountId),
          _.locationId -> lift(destLocationId)
        )
    }
    Future(ctx.run(updateQuery)).map(_ => ())
  }

  private def getExpirationFromFilter(filterType: FilterStateType, alarmId: Int, deviceId: UUID, locationId: UUID, userId: UUID): Future[Option[LocalDateTime]] = {
    val filterStateQuery = quote {
      query[FilterState]
        .filter { filterState =>
          filterState.alarmId == lift(alarmId) &&
            filterState.`type` == lift(filterType: FilterStateType) &&
            filterState.expiration > lift(LocalDateTime.now()) &&
            (filterState.userId.contains(lift(userId)) ||
              filterState.locationId.contains(lift(locationId)) ||
              filterState.deviceId.contains(lift(deviceId)))
        }
        .sortBy { fs =>
          (fs.userId.contains(lift(userId)), fs.locationId.contains(lift(locationId)), fs.deviceId.contains(lift(deviceId)), fs.expiration)
        } (Ord(Ord.desc, Ord.desc, Ord.desc, Ord.asc))
    }
    Future(ctx.run(filterStateQuery)).map(_.headOption.map(cleanUpFilterState(_).expiration))
  }

  private def cleanUpFilterState(filterState: FilterState): FilterState =
    filterState
      .modify(_.userId).setToIf(filterState.userId.contains(nilUuid))(None)
      .modify(_.deviceId).setToIf(filterState.deviceId.contains(nilUuid))(None)
      .modify(_.locationId).setToIf(filterState.locationId.contains(nilUuid))(None)
      .modify(_.incidentId).setToIf(filterState.incidentId.contains(nilUuid))(None)

  private def getParentChildrenAlarms: Future[Map[Int, Set[Int]]] = {
    // TODO: Cache?
    val parentChildrenQuery = quote {
      query[Alarm]
        .filter(_.parentId.isDefined)
        .map(alarm => alarm.parentId.getOrNull -> alarm.id)
    }

    Future(ctx.run(parentChildrenQuery)).map { parentChildTuples =>
      parentChildTuples.groupBy(_._1).map { case (k, v) => (k, v.map(_._2).toSet)}
    }
  }

  // TODO: Rename/Move/Improve/Refactor/Rewrite all the following code.

  private implicit object LongDeserializer extends ByteStringDeserializer[Long] {
    override def deserialize(bs: ByteString): Long = bs.utf8String.toLong
  }

  private implicit object UuidDeserializer extends ByteStringDeserializer[UUID] {
    override def deserialize(bs: ByteString): UUID = UUID.fromString(bs.utf8String)
  }

  def refreshStatsCache(deviceIds: Set[UUID]): Future[Unit] = {
    Future.traverse(deviceIds) { deviceId =>
      // TODO: Retrieve all stats in a single call for all devices
      retrieveStatistics(StatisticsFilter(icdId = Some(deviceId)), byPassCache = true).flatMap { stats =>

        notifyFireWriter(deviceId.toString, stats)

        redis.del(statsKey(deviceId)).flatMap { _ =>
          redis.hmset(statsKey(deviceId), Map(
            "count.critical" -> stats.critical.count,
            "count.warning" -> stats.warning.count,
            "count.info" -> stats.info.count) ++ stats.alarmCount.map { case (id, count) => s"count.alarm.$id" -> count}
          )
        }
      }
    }.map(_ => ())
  }

  private def notifyFireWriter(deviceId: String, stats: Statistics): Future[Unit] = {
    // TODO: Lookup MAC Addresses in a single call.
    val eventualMaybeMacAddress: Future[Option[String]] = retrieveMacAddressByDeviceId(deviceId)

    eventualMaybeMacAddress.map { maybeMacAddress =>
      maybeMacAddress.foreach { macAddress =>
        val utcZone = ZoneOffset.UTC.normalized()
        val now = ZonedDateTime.now(utcZone).truncatedTo(ChronoUnit.SECONDS)
          .format(DateTimeFormatter.ISO_INSTANT.withZone(utcZone))

        val alarmCount = stats.alarmCount.map { case (alarmId, count) =>
          s"""{"id":$alarmId,"count":$count}"""
        }.mkString("[", ",", "]")
        val infoCount: Long = stats.info.count
        val warningCount: Long = stats.warning.count
        val criticalCount: Long = stats.critical.count

        val entity = HttpEntity(ContentType(MediaTypes.`application/json`),
          s"""{"notifications":{"fsUpdate":"$now","pending":{"infoCount":${infoCount},"warningCount":${warningCount},"criticalCount":${criticalCount},"alarmCount":$alarmCount}}}""")

        Http().singleRequest(
          HttpRequest(method = HttpMethods.POST, uri = s"$fireWriterBaseUrl/firestore/devices/$macAddress", entity = entity))
      }
    }
  }

  private def retrieveDeviceStats(deviceIds: Set[UUID]): Future[Statistics] = {
    Future.traverse(deviceIds.toSeq) { deviceId =>
      redis.hgetall[Long](statsKey(deviceId)).flatMap { statMap =>
        if (statMap.nonEmpty) {
          val infoCount = statMap.getOrElse("count.info", 0L)
          val warningCount = statMap.getOrElse("count.warning", 0L)
          val criticalCount = statMap.getOrElse("count.critical", 0L)

          val deviceInfoCount = Math.min(1L, infoCount)
          val deviceWarningCount = Math.min(1L, warningCount)
          val deviceCriticalCount = Math.min(1L, criticalCount)

          val deviceInfoAbsoluteCount = if (deviceWarningCount > 0) 0L else deviceInfoCount
          val deviceWarningAbsoluteCount = if (deviceCriticalCount > 0) 0L else deviceWarningCount

          Future.successful(Statistics(
            info = Stat(infoCount, DeviceStat(deviceInfoCount, deviceInfoAbsoluteCount)),
            warning = Stat(warningCount, DeviceStat(deviceWarningCount, deviceWarningAbsoluteCount)),
            critical = Stat(criticalCount, DeviceStat(deviceCriticalCount, deviceCriticalCount)),
            alarmCount = extractAlarmStats(statMap)
          ))
        } else {
          retrieveStatistics(StatisticsFilter(icdId = Some(deviceId)), byPassCache = true)
        }
      }
    }.map { statSet =>
      statSet.foldLeft(Statistics(Stat.empty, Stat.empty, Stat.empty, Map())) { (result, stats) =>
        result.copy(
          info = sumStats(result.info, stats.info),
          warning = sumStats(result.warning, stats.warning),
          critical = sumStats(result.critical, stats.critical),
          alarmCount = mergeMaps(result.alarmCount, stats.alarmCount)
        )
      }
    }
  }

  private def sumStats(s1: Stat, s2: Stat): Stat =
    Stat(
      count = s1.count + s2.count,
      devices = DeviceStat(
        count = s1.devices.count + s2.devices.count,
        absolute = s1.devices.absolute + s2.devices.absolute
      )
    )

  private def mergeMaps(m1: Map[Int, Long], m2: Map[Int, Long]): Map[Int, Long] = {
    m1 ++ m2.map { case (k, v) => k -> (v + m1.getOrElse(k, 0L)) }
  }

  private val AlarmIdExtractor = "count\\.alarm\\.([0-9]+)".r
  private def extractAlarmStats(statMap: Map[String, Long]): Map[Int, Long] = {
    statMap
      .withFilter { case (key, _) => key.startsWith("count.alarm.") }
      .map { case (key, count) =>
        val AlarmIdExtractor(alarmId) = key
        alarmId.toInt -> count
      }
  }

  private def retrieveDevicesByLocation(locationId: UUID): Future[Set[UUID]] = {
    redis.smembers[UUID](locationToDeviceLookupKey(locationId)).flatMap { devices =>
      if (devices.nonEmpty) Future.successful(devices.toSet)
      else retrieveDevicesByLocationFromDb(locationId)
    }
  }

  private def retrieveDevicesByLocationFromDb(locationId: UUID): Future[Set[UUID]] = {
    Future(ctx.run(quote {
      query[Incident]
        .filter(incident => incident.locationId == lift(locationId))
        .map(_.icdId)
        .distinct
    })).map { devices =>
      val lookupSetKey = locationToDeviceLookupKey(locationId)
      if (devices.nonEmpty) {
        redis.sadd(lookupSetKey, devices.map(_.toString): _*)
        redis.expire(lookupSetKey, 60) // 60s TTL
      }
      devices.toSet
    }
  }

  private def locationToDeviceLookupKey(locationId: UUID) = s"lookup:locationToDevice:$locationId"

  private def deviceIdToMacAddressLookupKey(deviceId: String) = s"lookup:deviceIdToMacAddress:$deviceId"

  private def statsKey(deviceId: UUID) = s"nrv2:device:$deviceId"

  private def sendNotificationsResponse(
                                         macAddress: String,
                                         alarmId: Int,
                                         snoozeTo: LocalDateTime
                                       ): Future[Unit] = {

    val mqttTopic = s"home/device/$macAddress/v1/notifications-response"
    val response = NotificationResponse(
      UUID.randomUUID().toString,
      DateTime.now.toIsoDateString(),
      alarmId,
      2,
      "",
      List(
        NotificationResponseAction(
          NotificationResponseAction.SNOOZE,
          snoozeTo.toInstant(ZoneOffset.UTC).toEpochMilli
        )
      )
    )

    Future(notificationsResponsePublisher
      .send[NotificationResponse](mqttTopic, response, serializeResponse))
  }

  private def sendAlertAckToDevice(incident: Incident, alarmSeverity: String): Future[Unit] = {
    val eventualMacAddress = retrieveMacAddressByDeviceId(incident.icdId.toString)

    eventualMacAddress.map { maybeMacAddress =>
      maybeMacAddress.fold(()) { macAddress =>
        val mqttTopic = s"home/device/$macAddress/v1/notifications-response/ack"
        val ack = AlertAck(
          incident.id.toString,
          Alert(incident.alarmId, alarmSeverity),
          IncidentStatus.toString(incident.status),
          IncidentReason.toString(incident.reason.getOrElse(-1)),
          DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(incident.updateAt)
        )

        notificationsResponsePublisher
          .send[AlertAck](mqttTopic, ack, serializeAck)
      }
    }
  }
}