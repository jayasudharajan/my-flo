package com.flo.task.scheduler.utils

import org.apache.log4j.{Level, Logger}

trait Logging {
  protected val logger = Logger.getLogger(getClass)
  logger.setLevel(Level.ALL)
}
