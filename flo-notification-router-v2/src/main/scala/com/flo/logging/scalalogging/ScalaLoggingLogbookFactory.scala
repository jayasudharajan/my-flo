package com.flo.logging.scalalogging

import com.typesafe.scalalogging.Logger
import com.flo.logging.{Logbook, LogbookFactory}
import org.slf4j.LoggerFactory

final class ScalaLoggingLogbookFactory extends LogbookFactory {

  override def apply(subscribingClass: Class[_]): Logbook =
    new ScalaLoggingLogbook(Logger(LoggerFactory.getLogger(subscribingClass)))

  override def apply(contextDescription: String): Logbook =
    new ScalaLoggingLogbook(Logger(LoggerFactory.getLogger(contextDescription)))
}
