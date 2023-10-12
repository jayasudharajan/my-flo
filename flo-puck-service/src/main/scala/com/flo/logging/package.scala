package com.flo

import com.flo.logging.scalalogging.ScalaLoggingLogbookFactory

package object logging {

  private val logbookFactory = new ScalaLoggingLogbookFactory

  def logbookFor(loggingClass: Class[_]): Logbook = logbookFactory(loggingClass)

  def logbookFor(contextDescription: String): Logbook = logbookFactory(contextDescription)

}
