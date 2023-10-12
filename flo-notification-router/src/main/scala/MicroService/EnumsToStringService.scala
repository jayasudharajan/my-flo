package MicroService

import com.flo.Enums.Notifications.{AlarmNotificationStatuses, AlarmSeverity}
import com.flo.Enums.ValveModes

class EnumsToStringService {

  def alarmNotificationStatusesToString(status: Int): String = status match {
    case AlarmNotificationStatuses.IGNORED => "Ignored"
    case AlarmNotificationStatuses.MUTED => "Muted"
    case AlarmNotificationStatuses.RESOLVED => "Resolved"
    case AlarmNotificationStatuses.UNRESOLVED => "Unresolved"
  }

  /**
    * Translate the Alarm Severity enum into its string value, it returns an empty string otherwise
    **/
  def alarmSeverityToString(severity: Int): String = severity match {
    case AlarmSeverity.HIGH =>
      "Critical"
    case AlarmSeverity.MEDIUM =>
      "Warning"
    case AlarmSeverity.LOW =>
      "Status Update"
    case _ =>
      ""
  }

  /**
    * This method will take the values from sw1 and sw2 from telemetry or snapshot and covert the combination into the valve state description text. It will return "Unknown" otherwise.
    **/
  def sw1Sw2ValuesToValveState(sw1: Int, sw2: Int): String = (sw1, sw2) match {
    case (1, 0) => "Open"
    case (0, 1) => "Closed"
    case (0, 0) => "In Transition"
    case (1, 1) => "Broken"
    case _ => "Unknown"
  }

  def systemModeToString(sm: Int): String = sm match {
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

}
