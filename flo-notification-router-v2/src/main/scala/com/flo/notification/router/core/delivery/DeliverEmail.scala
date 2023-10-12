package com.flo.notification.router.core.delivery

import java.time.OffsetDateTime

import com.flo.Enums.Apps.FloAppsNames
import com.flo.Enums.Notifications.AlarmSeverity
import com.flo.Models.KafkaMessages.{EmailFeatherMessage, EmailRecipient, SendWithUsData}
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.sdk.model.{Alarm, SystemMode}
import org.joda.time.format.DateTimeFormat
import org.joda.time.{DateTime, DateTimeZone}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private[core] class DeliverEmail(
    retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever,
    localizationService: LocalizationService,
    buildCallbackHook: (AlarmIncidentId, UserId) => String,
    sendEmail: EmailSender
)(implicit ec: ExecutionContext)
    extends Deliver {

  override def apply(alarmIncident: AlarmIncident,
                     device: Device,
                     user: User,
                     alarm: Alarm,
                     schedule: Option[OffsetDateTime]): Future[Unit] = {
    val deliveryMediumTemplate = retrieveDeliveryMediumTemplate(
      alarm.id,
      SystemMode.toString(alarmIncident.systemMode),
      EmailMedium,
      user.account.accountType
    )

    val assetNames = Set(Option(deliveryMediumTemplate.body.name), deliveryMediumTemplate.body.fallback).flatten
    val eventualLocalizedBodies =
      localizationService.retrieveLocalizedTexts(assetNames, localization.Email, user.locale, Map())
    val eventualAlarmMetadata               = getAlarmMetadata(user, device, alarm, alarmIncident)
    val eventualLocalizedUnitSystemMetadata = getMeasurementUnitsMetadata(user)

    for {
      localizedBodies             <- eventualLocalizedBodies
      alarmMetadata               <- eventualAlarmMetadata
      localizedUnitSystemMetadata <- eventualLocalizedUnitSystemMetadata
    } yield {
      val localizedBody = localizedBodies
        .get(deliveryMediumTemplate.body.name)
        .filterNot(_.isEmpty)
        .orElse {
          deliveryMediumTemplate.body.fallback
            .flatMap { fallback =>
              localizedBodies.get(fallback)
            }
        }
        .getOrElse("")

      val emailMessage = EmailFeatherMessage(
        alarmIncident.id,
        None,
        FloAppsNames.NOTIFICATION_ROUTER,
        DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString,
        None,
        Set(
          EmailRecipient(
            Some(user.firstName),
            user.email,
            SendWithUsData(
              localizedBody,
              None,
              Map(
                "user"                    -> getUserMetadata(user, device.location, device),
                "alarm"                   -> alarmMetadata,
                "data"                    -> getTelemetryMetadata(alarmIncident.snapshot),
                "measurement_unit_system" -> localizedUnitSystemMetadata
              )
            )
          )
        ),
        Some(buildCallbackHook(alarmIncident.id, user.id))
      )

      sendEmail(
        buildDeliveryId(EmailMedium, alarm.id, user.id, device.id, alarmIncident.id),
        emailMessage,
        schedule
      )
    }
  }

  private def toString(value: Option[Any]): String = value.map(_.toString).getOrElse("")

  private def getTelemetryMetadata(snapshot: TelemetrySnapshot): Map[String, String] = Map(
    "temperature_minimum"         -> toString(snapshot.tmin),
    "temperature_maximum"         -> toString(snapshot.tmax),
    "pressure_minimum"            -> toString(snapshot.pmin),
    "pressure_maximum"            -> toString(snapshot.pmax),
    "flow_totalization_limit"     -> toString(snapshot.ftl),
    "flow_duration_limit"         -> toString(snapshot.efl),
    "per_event_flow_limit"        -> toString(snapshot.efl),
    "maximum_allowable_flow_rate" -> toString(snapshot.frl),
    "event_flow"                  -> toString(snapshot.ef),
    "event_flow_duration"         -> toString(snapshot.efd),
    "flow_totalization"           -> toString(snapshot.ft),
    "humidity_minimum"            -> toString(snapshot.limitHumidityMin),
    "humidity_maximum"            -> toString(snapshot.limitHumidityMax),
    "battery_percent_minimum"     -> toString(snapshot.limitBatteryMin),
  )

  private val TemperatureNamePrefix         = "temperature.name."
  private val TemperatureAbbreviationPrefix = "temperature.abbreviation."
  private val PressureNamePrefix            = "pressure.name."
  private val PressureAbbreviationPrefix    = "pressure.abbreviation."
  private val VolumeNamePrefix              = "volume.name."
  private val VolumeAbbreviationPrefix      = "volume.abbreviation."

  // TODO: Use variables and arguments from LocalizationService
  private def getMeasurementUnitsMetadata(user: User): Future[Map[String, String]] = {
    val unitSystem              = localizationService.getUnitSystemString(user.unitSystem.toRight(user.locale))
    val temperatureName         = p"$TemperatureNamePrefix$unitSystem"
    val temperatureAbbreviation = p"$TemperatureAbbreviationPrefix$unitSystem"
    val pressureName            = p"$PressureNamePrefix$unitSystem"
    val pressureAbbreviation    = p"$PressureAbbreviationPrefix$unitSystem"
    val volumeName              = p"$VolumeNamePrefix$unitSystem"
    val volumeAbbreviation      = p"$VolumeAbbreviationPrefix$unitSystem"

    localizationService
      .retrieveLocalizedTexts(
        Set(
          temperatureName,
          temperatureAbbreviation,
          pressureName,
          pressureAbbreviation,
          volumeName,
          volumeAbbreviation
        ),
        localization.Display,
        user.locale,
        Map()
      )
      .map { localizedTextMap =>
        Map(
          "temperature_name"   -> localizedTextMap(temperatureName),
          "temperature_abbrev" -> localizedTextMap(temperatureAbbreviation),
          "pressure_name"      -> localizedTextMap(pressureName),
          "pressure_abbrev"    -> localizedTextMap(pressureAbbreviation),
          "volume_name"        -> localizedTextMap(volumeName),
          "volume_abbrev"      -> localizedTextMap(volumeAbbreviation)
        )
      }
  }

  private def getUserMetadata(user: User, location: Location, device: Device): Map[String, String] = Map(
    "firstname"         -> user.firstName,
    "full_address"      -> getFullAddress(location),
    "address"           -> location.address,
    "address_2"         -> location.address2.getOrElse(""),
    "city"              -> location.city,
    "state"             -> location.state.getOrElse(""),
    "zip"               -> location.postalCode,
    "is_landlord"       -> user.isLandLord.toString,
    "is_tenant"         -> user.isTenant.toString,
    "device_nickname"   -> device.nickname.getOrElse(""),
    "location_nickname" -> location.nickname.getOrElse("")
  )

  private def getAlarmMetadata(user: User,
                               device: Device,
                               alarm: Alarm,
                               alarmIncident: AlarmIncident): Future[Map[String, String]] = {
    val snapshot = alarmIncident.snapshot

    val eventualLocalizedSystemMode =
      localizationService.retrieveLocalizedSystemMode(user.locale, alarmIncident.systemMode)
    val eventualLocalizedValveState    = getLocalizedValveState(user.locale, snapshot.sw1, snapshot.sw2, snapshot.v)
    val eventualLocalizedAlarmSeverity = getLocalizedAlarmSeverity(user.locale, alarm.severity)
    val eventualLocalizedArgs          = localizationService.buildDefaultLocalizedArgs(alarmIncident, user, device)
    val eventualLocalizedAlarmDisplayName = localizationService.retrieveLocalizedAlarmDisplayName(
      user.locale,
      alarm.id,
      SystemMode.toString(alarmIncident.systemMode)
    )

    for {
      systemMode           <- eventualLocalizedSystemMode
      valveState           <- eventualLocalizedValveState
      alarmSeverity        <- eventualLocalizedAlarmSeverity
      defaultLocalizedArgs <- eventualLocalizedArgs
      alarmMessage <- localizationService.retrieveLocalizedAlarmMessage(
                       user.locale,
                       alarm.id,
                       SystemMode.toString(alarmIncident.systemMode),
                       defaultLocalizedArgs
                     )
      alarmName <- eventualLocalizedAlarmDisplayName
    } yield {
      Map(
        "system_mode_enum"     -> alarmIncident.systemMode.toString,
        "system_mode"          -> systemMode,
        "water_flow_rate"      -> localizationService.getLocalizedRate(user.unitSystem.toRight(user.locale), snapshot.fr),
        "temperature"          -> localizationService.getLocalizedTemperature(user.unitSystem.toRight(user.locale), snapshot.t),
        "pressure"             -> localizationService.getLocalizedPressure(user.unitSystem.toRight(user.locale), snapshot.p),
        "humidity"             -> roundValue(snapshot.humidity),
        "battery_percent"      -> snapshot.batteryPercent.map(_.toString).getOrElse(""),
        "valve_state"          -> valveState,
        "id"                   -> alarm.id.toString,
        "alarm_id"             -> alarm.id.toString,
        "name"                 -> alarmName,
        "type"                 -> alarmSeverity,
        "time"                 -> getLocalizedIncidentTime(device.location.timezone, alarmIncident.timestamp),
        "friendly_description" -> alarmMessage,
        "alarm_id_system_mode" -> p"${alarm.id}_${alarmIncident.systemMode}"
      )
    }
  }

  private def roundValue(maybeValue: Option[Double]): String =
    maybeValue.fold("") { value =>
      val decimals = ((value - value.toInt) * 100).toInt
      if (decimals != 0) f"$value%.1f" else value.toInt.toString
    }

  private def getFullAddress(location: Location): String = {
    val address2 = location.address2.map(_.trim).getOrElse("")
    val state    = location.state.map(_.trim).getOrElse("")
    p"${location.address.trim} $address2 ${location.city.trim}, $state, ${location.postalCode.trim}"
  }

  // TODO: Move these methods to LocalizationService
  private def getLocalizedValveState(locale: String,
                                     sw1: Option[Int],
                                     sw2: Option[Int],
                                     v: Option[Int]): Future[String] = {
    val valveState = v
      .map(getValveStateByV)
      .getOrElse(getValveState(sw1.getOrElse(-1), sw2.getOrElse(-1)))

    localizationService.retrieveLocalizedText(valveState, localization.Display, locale, Map())
  }

  private def getValveStateByV(v: Int): String = v match {
    case 0 => "valveState.closed"
    case 1 => "valveState.open"
    case 2 => "valveState.inTransition"
    case 3 => "valveState.broken"
    case 4 => "valveState.unknown"
  }

  private def getValveState(sw1: Int, sw2: Int): String =
    (sw1, sw2) match {
      case (1, 0) => "valveState.open"
      case (0, 1) => "valveState.closed"
      case (0, 0) => "valveState.inTransition"
      case (1, 1) => "valveState.broken"
      case _      => "valveState.unknown"
    }

  private def getLocalizedAlarmSeverity(locale: String, severity: Int): Future[String] = {
    val severityStr = severity match {
      case AlarmSeverity.HIGH   => "severity.critical"
      case AlarmSeverity.MEDIUM => "severity.warning"
      case AlarmSeverity.LOW    => "severity.statusUpdate"
    }
    localizationService.retrieveLocalizedText(severityStr, localization.Display, locale, Map())
  }

  // TODO: Check where exactly this is used and let Localization Service do its thing.
  private def getLocalizedIncidentTime(timezone: String, incidentTime: Long): String = {
    val timeZone           = DateTimeZone.forID(timezone)
    val format             = DateTimeFormat.forPattern("MMMM d, YYYY 'at' h:mm")
    val timeZoneFormat     = DateTimeFormat.forPattern("z")
    val halfOfTheDayFormat = DateTimeFormat.forPattern("a")

    val date             = new DateTime(incidentTime, timeZone).toString(format)
    val dateTimezone     = new DateTime(incidentTime, timeZone).toString(timeZoneFormat).toLowerCase()
    val dateHalfOfTheDay = new DateTime(incidentTime, timeZone).toString(halfOfTheDayFormat).toLowerCase()

    p"$date $dateHalfOfTheDay $dateTimezone"
  }
}
