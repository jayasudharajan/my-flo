package com.flo.logging

trait LogbookFactory {
  def apply(subscribingClass: Class[_]): Logbook

  def apply(contextDescription: String): Logbook
}
