package com.flo.json4s

import org.json4s.native.JsonMethods._
import org.json4s.native.Serialization.write
import org.json4s.{ext, DefaultFormats}

trait SimpleSerialization {
  implicit lazy val formats = DefaultFormats.lossless ++ ext.JodaTimeSerializers.all

  def serializeToSnakeCase[T <: AnyRef: Manifest](message: T): String = {
    val serialized = write(message)
    compact(render(parse(serialized).snakizeKeys))
  }

  def deserializeFromCamelCase[T <: AnyRef: Manifest](message: String): T =
    parse(message).camelizeKeys.extract[T]

  def serializeWithoutConversions[T <: AnyRef: Manifest](message: T): String = {
    val serialized = write(message)
    compact(render(parse(serialized)))
  }
}

object SimpleSerialization extends SimpleSerialization
