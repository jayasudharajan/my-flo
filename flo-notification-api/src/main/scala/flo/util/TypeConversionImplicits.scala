package flo.util

import java.util.UUID

object TypeConversionImplicits {
  implicit def string2UUID(x: String): UUID =
    UUID.fromString(x)

  implicit def uuid2String(x: UUID): String =
    x.toString

  implicit def stringList2UUIDList(x: List[String]): List[UUID] =
    x.map(string2UUID(_))

  implicit def uuidList2StringList(x: List[UUID]): List[String] =
    x.map(uuid2String(_))
}
