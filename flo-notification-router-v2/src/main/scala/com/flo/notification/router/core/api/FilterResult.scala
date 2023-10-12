package com.flo.notification.router.core.api

import cats.data.NonEmptySet
import cats.syntax.set._

sealed trait FilterResult {
  def merge(other: FilterResult): FilterResult
  def allows(medium: DeliveryMedium): Boolean
}

case class NoMediumsAllowed(reason: FilterReason) extends FilterResult {
  override def merge(other: FilterResult): FilterResult = this

  override def allows(medium: DeliveryMedium): Boolean = false
}

case object AllMediumsAllowed extends FilterResult {
  override def merge(other: FilterResult): FilterResult = other

  override def allows(medium: DeliveryMedium): Boolean = true
}

case class AllowedMediums(mediums: NonEmptySet[DeliveryMedium]) extends FilterResult {
  override def merge(other: FilterResult): FilterResult = other match {
    case noMediumsAllowed: NoMediumsAllowed => noMediumsAllowed

    case AllMediumsAllowed => this

    case _ @AllowedMediums(otherMediums) =>
      mediums.intersect(otherMediums).toNes match {
        case Some(intersection) => AllowedMediums(intersection)
        case _                  => NoMediumsAllowed(MultipleFilterMerge)
      }
  }

  override def allows(medium: DeliveryMedium): Boolean = mediums.contains(medium)
}
