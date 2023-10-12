package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

import io.getquill.Embedded

sealed trait FilterStateType
case object Snooze extends FilterStateType
case object MaxFrequencyCap extends FilterStateType

object FilterStateType {
  private val SnoozeId = 1
  private val MaxFrequencyCapId = 2

  private val SnoozeStr = "snooze"
  private val MaxFrequencyCapStr = "max-frequency-cap"

  def toId(filterStateType: FilterStateType): Int = filterStateType match {
    case Snooze => SnoozeId
    case MaxFrequencyCap => MaxFrequencyCapId
  }

  def toString(filterStateType: FilterStateType): String = filterStateType match {
    case Snooze => SnoozeStr
    case MaxFrequencyCap => MaxFrequencyCapStr
  }

  def fromId(filterStateTypeId: Int): Option[FilterStateType] = filterStateTypeId match {
    case SnoozeId => Some(Snooze)
    case MaxFrequencyCapId => Some(MaxFrequencyCap)
    case _ => None
  }

  def fromIdUnsafe(filterStateTypeId: Int): FilterStateType = filterStateTypeId match {
    case SnoozeId => Snooze
    case MaxFrequencyCapId => MaxFrequencyCap
  }

  def fromString(filterStateTypeStr: String): Option[FilterStateType] = filterStateTypeStr match {
    case SnoozeStr => Some(Snooze)
    case MaxFrequencyCapStr => Some(MaxFrequencyCap)
    case _ => None
  }

  def fromStringUnsafe(filterStateTypeStr: String): FilterStateType = filterStateTypeStr match {
    case SnoozeStr => Snooze
    case MaxFrequencyCapStr => MaxFrequencyCap
  }
}

case class FilterState(id: Option[UUID],
                       alarmId: Int,
                       `type`: FilterStateType,
                       deviceId: Option[UUID],
                       incidentId: Option[UUID],
                       locationId: Option[UUID],
                       userId: Option[UUID],
                       expiration: LocalDateTime,
                       createdAt: Option[LocalDateTime],
                      ) extends Embedded

