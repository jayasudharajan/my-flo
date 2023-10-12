package com.flo.util

import java.util.UUID

object TypeConversions {
  object Uuid {
    implicit def stringToUuid(str: String): UUID  = UUID.fromString(str)
    implicit def uuidToString(uuid: UUID): String = uuid.toString
  }
}
