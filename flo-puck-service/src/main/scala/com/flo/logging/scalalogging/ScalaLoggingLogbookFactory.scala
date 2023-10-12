package com.flo.logging.scalalogging

import com.flo.logging.{Logbook, LogbookFactory}
import com.typesafe.scalalogging.Logger
import org.slf4j.LoggerFactory

final class ScalaLoggingLogbookFactory extends LogbookFactory {

  override def apply(subscribingClass: Class[_]): Logbook =
    new ScalaLoggingLogbook(Logger(LoggerFactory.getLogger(subscribingClass)))

  override def apply(contextDescription: String): Logbook =
    new ScalaLoggingLogbook(Logger(LoggerFactory.getLogger(contextDescription)))
}
