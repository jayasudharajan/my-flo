package com.flo.notification.sdk.model

object SystemMode {
  val Home = 2
  val Away = 3
  val Sleep = 5
  val Unknown = 0

  private val homeString = "home"
  private val awayString = "away"
  private val sleepString = "sleep"
  private val unknownString = "unknown"

  def toString(systemMode: Int): String = systemMode match {
    case Home => homeString
    case Away => awayString
    case Sleep => sleepString
    case _ => unknownString
  }

  def fromString(systemMode: String): Int = systemMode match {
    case s if s == homeString => Home
    case s if s == awayString => Away
    case s if s == sleepString => Sleep
    case _ => Unknown
  }
}
