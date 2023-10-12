package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

case class Filter[T](operator: String, value: T)

object Filter {
  private def getFilter(text: String): Filter[String] = {
    val regex = """(eq:|lt:|let:|gt:|get:)?(.*)""".r

    text match {
      case regex(operator, value) if operator != null => Filter[String](operator.replace(":", ""), value)
      case value => Filter[String]("eq", value)
    }
  }

  def generateStringFilters(filters: Seq[String]): Seq[Filter[String]] =
    filters.map(filter => getFilter(filter))

  def generateIntFilters(filters: Seq[String]): Seq[Filter[Int]] =
    generateStringFilters(filters).map(x => Filter[Int](x.operator, x.value.toInt))

  def generateLocalDateTimeFilters(filters: Seq[String]): Seq[Filter[LocalDateTime]] = {
    generateStringFilters(filters)
      .map(x => Filter[LocalDateTime](x.operator, LocalDateTime.parse(x.value, DateTimeFormatter.ISO_DATE_TIME)))
  }

  def generateFilters[T](filters: Seq[String], mapValue: String => T): Seq[Filter[T]] = {
    generateStringFilters(filters).map(x => Filter[T](x.operator, mapValue(x.value)))
  }
}