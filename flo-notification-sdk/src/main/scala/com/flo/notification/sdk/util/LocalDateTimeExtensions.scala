package com.flo.notification.sdk.util

import java.time.LocalDateTime
import io.getquill.context.sql.SqlContext

trait LocalDateTimeExtensions {
  this: SqlContext[_, _] =>

  implicit class LocalDateTimeQuotes(left: LocalDateTime) {
    def >(right: LocalDateTime) = quote(infix"$left > $right".as[Boolean])

    def <(right: LocalDateTime) = quote(infix"$left < $right".as[Boolean])

    def ==(right: LocalDateTime) = quote(infix"$left = $right".as[Boolean])

    def isAfter(right: LocalDateTime) = quote(infix"$left > $right".as[Boolean])

    def isBefore(right: LocalDateTime) = quote(infix"$left < $right".as[Boolean])

    def isEqual(right: LocalDateTime) = quote(infix"$left = $right".as[Boolean])
  }
}