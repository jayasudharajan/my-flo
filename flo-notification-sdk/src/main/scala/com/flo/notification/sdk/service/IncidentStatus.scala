package com.flo.notification.sdk.service

object IncidentStatus {
  val Received = 1
  val Filtered = 2
  val Triggered = 3
  val Resolved = 4

  private val ReceivedString = "received"
  private val FilteredString = "filtered"
  private val TriggeredString = "triggered"
  private val ResolvedString = "resolved"
  private val UnknownString = "unknown"

  def toString(alarmEventStatus: Int): String = alarmEventStatus match {
    case Received => ReceivedString
    case Filtered => FilteredString
    case Triggered => TriggeredString
    case Resolved => ResolvedString
    case _ => UnknownString
  }

  def fromString(alarmEventStatusName: String): Int = alarmEventStatusName match {
    case ReceivedString => Received
    case FilteredString => Filtered
    case TriggeredString => Triggered
    case ResolvedString => Resolved
    case _ => 0
  }
}
