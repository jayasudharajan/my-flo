package com.flo.notification.sdk.model

object Severity {
  val Critical = 1
  val Warning = 2
  val Info = 3
  
  private val infoString = "info"
  private val warningString = "warning"
  private val criticalString = "critical"
  private val unknownString = "unknown"

  def toString(severity: Int): String = severity match {
    case Info => infoString
    case Warning => warningString
    case Critical => criticalString
    case _ => unknownString
  }

  def fromString(severityName: String): Int = severityName match {
    case s if s == infoString => Info
    case s if s == warningString => Warning
    case s if s == criticalString => Critical
    case _ => 0
  }
}
