package com.flo.localization

import com.flo.Enums.ValveModes
import com.flo.notification.router.core.api.localization.{AssetType, Display, Email, PushNotification, Sms, VoiceCall}
import perfolation._

private[localization] object Assets {
  val ImperialSuffix = "imperial"
  val MetricSuffix   = "metric"

  val DateFormat = "nr.date.format"

  def volumeAbbrev(unitSystemSuffix: String)      = p"volume.abbreviation.$unitSystemSuffix"
  def volumeName(unitSystemSuffix: String)        = p"volume.name.$unitSystemSuffix"
  def temperatureAbbrev(unitSystemSuffix: String) = p"temperature.abbreviation.$unitSystemSuffix"
  def temperatureName(unitSystemSuffix: String)   = p"temperature.name.$unitSystemSuffix"
  def pressureAbbrev(unitSystemSuffix: String)    = p"pressure.abbreviation.$unitSystemSuffix"
  def pressureName(unitSystemSuffix: String)      = p"pressure.name.$unitSystemSuffix"
  def rateName(unitSystemSuffix: String)          = p"rate.name.$unitSystemSuffix"
  def rateAbbrev(unitSystemSuffix: String)        = p"rate.abbreviation.$unitSystemSuffix"
  def systemMode(systemMode: Int): String = systemMode match {
    case ValveModes.SLEEP => "systemMode.sleep"
    case ValveModes.HOME  => "systemMode.home"
    case ValveModes.AWAY  => "systemMode.away"
    case _                => "systemMode.unknown"
  }
  def alarmMessage(alarmId: Int, systemMode: String)     = p"${alarmPrefix(alarmId, systemMode)}.message"
  def alarmTitle(alarmId: Int, systemMode: String)       = p"${alarmPrefix(alarmId, systemMode)}.title"
  def alarmDisplayName(alarmId: Int, systemMode: String) = p"${alarmPrefix(alarmId, systemMode)}.name"
  def alarmDescription(alarmId: Int, systemMode: String) = p"${alarmPrefix(alarmId, systemMode)}.description"
  def appType(appTypeCode: Int)                          = p"nr.appType.$appTypeCode"

  def assetTypeToString(assetType: AssetType): String =
    assetType match {
      case Email            => "email"
      case Sms              => "sms"
      case PushNotification => "push"
      case VoiceCall        => "voice"
      case Display          => "display"
    }

  private def alarmPrefix(alarmId: Int, systemMode: String) = p"nr.alarm.$alarmId.$systemMode"
}
