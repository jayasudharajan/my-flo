package com.flo.notification.sdk.model

object ActionType {
  val WebLink = 0
  val AppPath = 1
  val PhoneNumber = 2

  def toString(actionType: Int): String = actionType match {
    case WebLink => "webLink"
    case AppPath => "appPath"
    case PhoneNumber => "phoneNumber"
    case _ => "unknown"
  }
}

