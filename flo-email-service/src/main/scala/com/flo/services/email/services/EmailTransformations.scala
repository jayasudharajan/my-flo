package com.flo.services.email.services

import com.flo.Enums.Notifications.AlarmSeverity
import com.flo.Enums.ValveModes
import com.flo.Models.KafkaMessages.EmailMessage
import com.flo.Models.Location
import com.flo.Models.Users.UserContactInformation
import com.flo.services.email.models.ActorEmailMessage
import com.flo.services.email.utils.ApplicationSettings
import org.joda.time.format.DateTimeFormat
import org.joda.time.{DateTime, DateTimeZone}
import scala.collection.JavaConverters._
import scala.math.BigDecimal.RoundingMode

object EmailTransformations {
  def toActorEmailMessage(message: EmailMessage): ActorEmailMessage = {
    ActorEmailMessage(
      templateId = message.notification.get.messageTemplates.emailProperties.templateId,
      recipientMap = getRecipient(message.userContactInformation),
      senderMap = getSender(message.userContactInformation),
      emailTemplateData = getTemplateData(message),
      espAccount = None,
      webHook = message.statusCallback
    )
  }

  private def getTemplateData(message: EmailMessage): Map[String, Object] = {
    var userMap = Map[String, String]()
    var alarmMap = Map[String, String]()
    var dataMap = Map[String, String]()
    var unitSystemMap = Map[String, String]()

    userMap += ("firstname" -> message.userContactInformation.get.firstName.getOrElse(""))
    userMap += ("full_address" -> getFullAddress(message.location))
    userMap += ("address" -> message.location.get.address.getOrElse("").trim)
    userMap += ("address_2" -> message.location.get.address2.getOrElse("").trim)

    userMap += ("city" -> message.location.get.city.getOrElse("").trim)
    userMap += ("state" -> message.location.get.state.getOrElse("").trim)
    userMap += ("zip" -> message.location.get.postalCode.getOrElse("").trim)

    alarmMap += ("system_mode" -> systemModenator5000(message.icd.get.systemMode.getOrElse(ValveModes.UNKNOWN)))
    alarmMap += ("water_flow_rate" -> toString(message.telemetry.get.wf))
    alarmMap += ("temperature" -> toString(message.telemetry.get.t))
    alarmMap += ("pressure" -> toString(message.telemetry.get.p))
    alarmMap += ("valve_state" -> getTheV(message.telemetry.get.sw1, message.telemetry.get.sw2, message.telemetry.get.v))
    alarmMap += ("id" -> intToString(Some(message.notification.get.internalId)))
    alarmMap += ("alarm_id" -> intToString(Some(message.notification.get.alarmId)))
    alarmMap += ("name" -> message.notification.get.messageTemplates.friendlyName)
    alarmMap += ("type" -> getAlarmSeverity(message.notification.get.severity))
    alarmMap += ("time" -> timenator5000(
      message.location.get.timezone,
      message.notificationTime.getOrElse(//grabs ts if notification time is not available
        message.ts.getOrElse(// grabs current UTC if TS is not available
          DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString
        )
      )
    )
      )
    alarmMap += ("friendly_description" -> message.friendlyDescription.getOrElse(""))


    dataMap += ("temperature_minimum" -> toString(message.telemetry.get.tmin))
    dataMap += ("temperature_maximum" -> toString(message.telemetry.get.tmax))
    dataMap += ("pressure_minimum" -> toString(message.telemetry.get.pmin))
    dataMap += ("pressure_maximum" -> toString(message.telemetry.get.pmax))
    dataMap += ("flow_totalization_limit" -> toString(message.telemetry.get.ftl))
    dataMap += ("flow_duration_limit" -> intToString(message.telemetry.get.fdl))
    dataMap += ("per_event_flow_limit" -> toString(message.telemetry.get.pefl))
    dataMap += ("maximum_allowable_flow_rate" -> toString(message.telemetry.get.mafr))
    dataMap += ("event_flow" -> toString(message.telemetry.get.pef))
    dataMap += ("event_flow_duration" -> message.telemetry.get.fd.getOrElse("Unknown").toString)
    dataMap += ("flow_totalization" -> toString(message.telemetry.get.ft))

    //measurementunitSystem
    if (message.measurementUnitSystem.isDefined && message.measurementUnitSystem.nonEmpty) {
      unitSystemMap += ("id" -> message.measurementUnitSystem.get.id)
      unitSystemMap += ("name" -> message.measurementUnitSystem.get.name)
      unitSystemMap += ("temperature_name" -> message.measurementUnitSystem.get.units.temperature.name)
      unitSystemMap += ("temperature_abbrev" -> message.measurementUnitSystem.get.units.temperature.abbrev)
      unitSystemMap += ("pressure_name" -> message.measurementUnitSystem.get.units.pressure.name)
      unitSystemMap += ("pressure_abbrev" -> message.measurementUnitSystem.get.units.pressure.abbrev)
      unitSystemMap += ("volume_name" -> message.measurementUnitSystem.get.units.volume.name)
      unitSystemMap += ("volume_abbrev" -> message.measurementUnitSystem.get.units.volume.abbrev)
    }

    val templateMap = Map("user" -> userMap.asJava, "alarm" -> alarmMap.asJava, "data" -> dataMap.asJava, "measurement_unit_system" -> unitSystemMap.asJava)
    templateMap
  }

  private def timenator5000(locationTz: Option[String], notificatonTime: String): String = {
    var timeZone = DateTimeZone.UTC
    if (locationTz.isDefined) {
      try {
        timeZone = DateTimeZone.forID(locationTz.get)
      }
      catch {
        case e: Throwable => println(e.printStackTrace())
          timeZone = DateTimeZone.UTC
      }
    }

    val format = DateTimeFormat.forPattern("MMMM d, YYYY 'at' h:mm")
    val timeZoneFormat = DateTimeFormat.forPattern("z")
    val halfOfTheDayFormat = DateTimeFormat.forPattern("a")


    val date = new DateTime(notificatonTime, timeZone).toString(format)
    val dateTimezone = new DateTime(notificatonTime, timeZone).toString(timeZoneFormat).toLowerCase()
    val dateHalfOfTheDay = new DateTime(notificatonTime, timeZone).toString(halfOfTheDayFormat).toLowerCase()


    s"$date $dateHalfOfTheDay $dateTimezone"
  }

  private def systemModenator5000(sm: Int): String = sm match {
    case ValveModes.VACATION =>
      "vacation"
    case ValveModes.UNKNOWN =>
      "unknown"
    case ValveModes.MANUAL =>
      "manual"
    case ValveModes.HOME =>
      "home"
    case ValveModes.AUTORUN =>
      "autorun"
    case ValveModes.AWAY =>
      "away"
    case _ =>
      "unknown"
  }

  private def toString(value: Option[Double]): String = {
    value.map(x => roundDouble(x).toString).getOrElse("")
  }

  private def roundDouble(v: Double): Double = if (v != 0) Math.round(v * 100.0) / 100.0 else 0.0

  private def intToString(value: Option[Int]): String = {
    value.map(x => x.toString).getOrElse("")
  }

  private def getTheV(sw1: Option[Int], sw2: Option[Int], v: Option[Int]): String = v match {
    case Some(theV) => getValveStateByV(theV)
    case _ => getValveState(sw1.getOrElse(-1), sw2.getOrElse(-1))
  }

  private def getValveStateByV(v: Int): String = v match {
    case 0 => "Closed"
    case 1 => "Open"
    case 2 => "In Transition"
    case 3 => "Broken"
    case 4 => "Unknown"
  }

  private def getValveState(sw1: Int, sw2: Int): String = {
    (sw1, sw2) match {
      case (1, 0) => "Open"
      case (0, 1) => "Closed"
      case (0, 0) => "In Transition"
      case (1, 1) => "Broken"
      case _ => "Unknown"
    }
  }

  private def getAlarmSeverity(severity: Int): String = {
    severity match {
      case AlarmSeverity.HIGH => "Critical"
      case AlarmSeverity.MEDIUM => "Warning"
      case AlarmSeverity.LOW => "Status Update"
    }
  }

  private def getAddress(location: Option[Location]): String = location match {
    case Some(loc) =>
      if (loc.address.isDefined && loc.address2.isDefined) {
        s"${loc.address.get} ${loc.address2.get}"
      }
      else if (loc.address.isDefined) {
        s"${loc.address.get}"
      }
      else
        ""
    case None => ""
  }

  private def getFullAddress(location: Option[Location]): String = location match {
    case Some(loc) =>
      if (loc.address.isDefined && loc.address2.isDefined && loc.city.isDefined && loc.state.isDefined && loc.postalCode.isDefined) {
        s"${loc.address.get.trim} ${loc.address2.get.trim} ${loc.city.get.trim}, ${loc.state.get.trim}, ${loc.postalCode.get.trim}"
      }
      else if (loc.address.isDefined && loc.city.isDefined && loc.state.isDefined && loc.postalCode.isDefined) {
        s"${loc.address.get.trim} ${loc.city.get.trim}, ${loc.state.get.trim}, ${loc.postalCode.get.trim}"
      }
      else if (loc.address.isDefined) {
        s"${loc.address.get.trim} ${loc.address2.getOrElse("").trim} ${loc.city.getOrElse("").trim} ${loc.state.getOrElse("").trim} ${loc.postalCode.getOrElse("").trim}".trim
      }
      else
        ""
    case None => ""
  }

  /**
    * deprecated: now we ge this from ICDALARMNOTIFICATIONDELIVERYRULE
    **/
  private def getTemplateId(severity: Int): String = severity match {
    case AlarmSeverity.HIGH => ApplicationSettings.emailTemplates.alarmSeverityHigh
    case AlarmSeverity.MEDIUM => ApplicationSettings.emailTemplates.alarmSeverityMedium
    case AlarmSeverity.LOW => ApplicationSettings.emailTemplates.alarmSeverityLow
  }

  private def getSender(userContactInformation: Option[UserContactInformation]): Map[String, Object] = {
    val cSEmail = isCSEmail(userContactInformation.get.email.get)
    val address = if (cSEmail) "cs@meetflo.com" else ApplicationSettings.sendWithUs.defaultEmailAddress
    val replyTo = if (cSEmail) "cs@meetflo.com" else ApplicationSettings.sendWithUs.replyToEmailAddress
    val sMap = Map(
      "name" -> "Flotechnologies",
      "address" -> address,
      "reply_to" -> replyTo
    )

    sMap

    ///TODO: Add location properties
  }

  private def isCSEmail(email: String): Boolean = email.equalsIgnoreCase("support@meetflo.zendesk.com")


  private def getRecipient(userContactInformation: Option[UserContactInformation]): Map[String, Object] = userContactInformation match {
    case Some(userContactInfo) =>
      val rMap = Map(
        "name" -> getFullContactName(userContactInfo).getOrElse(userContactInfo.email.getOrElse(throw new IllegalArgumentException("no email found in userContactInformation"))),
        "address" -> userContactInfo.email.getOrElse(throw new IllegalArgumentException("no email found in userContactInformation"))
      )

      rMap
    case _ =>
      throw new IllegalArgumentException("user contact information cannot be empty")

  }

  private def getFullContactName(userContactInformation: UserContactInformation): Option[String] = {
    if (userContactInformation.firstName.isDefined && userContactInformation.lastName.isDefined) {
      Some(s"${userContactInformation.lastName.get}, ${userContactInformation.firstName.get}")
    }
    else if (userContactInformation.firstName.isDefined && userContactInformation.lastName.isEmpty) {
      userContactInformation.firstName
    }
    else if (userContactInformation.firstName.isEmpty && userContactInformation.lastName.isDefined) {
      userContactInformation.lastName
    }
    else None
  }
}