package com.flo.notification.router.core.api

import java.time.ZoneId

package object localization {
  type Locale            = String
  type AssetName         = String
  type LocalizationArgs  = Map[String, String]
  type TimeZoneRetriever = (Device, User) => ZoneId

  object Args {
    val AlarmName: String = "alarmName"
  }

  sealed trait AssetType
  case object Email            extends AssetType
  case object Sms              extends AssetType
  case object PushNotification extends AssetType
  case object VoiceCall        extends AssetType
  case object Display          extends AssetType
}
