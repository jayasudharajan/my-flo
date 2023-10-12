package com.flo.util

import java.util.UUID

trait Module {
  // Provides
  def generateUuid: String        = java.util.UUID.randomUUID().toString
  def toUuid(value: String): UUID = TypeConversions.Uuid.stringToUuid(value)
}
