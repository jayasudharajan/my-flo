package com.flo.logging.scalalogging

import com.flo.logging.Logbook
import com.typesafe.scalalogging.Logger

/**
  * Scala-logging implementation of a [[com.flo.logging.Logbook]].
  *
  * @param logger The scala-logging logger to adapt.
  */
final class ScalaLoggingLogbook(logger: Logger) extends Logbook {

  override def trace(message: => String): Unit = logger.trace(message)

  override def debug(message: => String): Unit = logger.debug(message)

  override def info(message: => String): Unit = logger.info(message)

  override def warn(message: => String): Unit = logger.warn(message)

  override def warn(message: => String, cause: => Throwable): Unit = logger.warn(message, cause)

  override def error(message: => String): Unit = logger.error(message)

  override def error(message: => String, cause: => Throwable): Unit = logger.error(message, cause)
}
