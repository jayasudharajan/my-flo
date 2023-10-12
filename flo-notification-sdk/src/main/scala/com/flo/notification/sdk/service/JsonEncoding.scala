package com.flo.notification.sdk.service

import io.getquill.{Literal, MappedEncoding, PostgresJdbcContext}
import org.json4s.jackson.JsonMethods.parse
import org.json4s.jackson.Serialization

trait JsonEncoding {
  implicit val formats = org.json4s.DefaultFormats
  implicit val encodeJSON = MappedEncoding[Map[String, Any], String](jsonAsMap => Serialization.write(jsonAsMap))
  implicit val decodeJSON = MappedEncoding[String, Map[String, Any]](jsonAsStr => parse(jsonAsStr).extract[Map[String, Any]])

  val jdbcContext: PostgresJdbcContext[Literal] // your context should go here

  import jdbcContext._

  implicit val jsonDecoder: Decoder[Map[String, Any]] =
    decoder((index, row) =>
      parse(row.getObject(index).toString).extract[Map[String, Any]]) // database-specific implementation

  implicit val jsonEncoder: Encoder[Map[String, Any]] =
    encoder(java.sql.Types.OTHER, (index, value, row) =>
      row.setObject(index, value, java.sql.Types.OTHER)) // database-specific implementation
}
