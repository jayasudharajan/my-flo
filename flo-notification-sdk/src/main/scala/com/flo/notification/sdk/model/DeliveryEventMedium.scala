package com.flo.notification.sdk.model

object DeliveryEventMedium {
  val Email = 2
  val PushNotification = 3
  val Sms = 4
  val VoiceCall = 5

  def toString(medium: Int): String = medium match {
    case Sms => "sms"
    case VoiceCall => "voice"
    case Email => "email"
    case PushNotification => "push"
  }
}