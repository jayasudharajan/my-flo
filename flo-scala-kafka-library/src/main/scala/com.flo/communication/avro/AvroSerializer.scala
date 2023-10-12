package com.flo.communication.avro

import java.io.ByteArrayOutputStream
import com.sksamuel.avro4s._

class AvroSerializer {
  def serialize[T <: Product : Encoder : SchemaFor](message: T): Array[Byte] = {
    serialize[T](List(message))
  }

  def serialize[T <: Product : Encoder : SchemaFor](messages: List[T]): Array[Byte] = {
    val schema = AvroSchema[T]
    val out = new ByteArrayOutputStream
    val avro = AvroOutputStream.binary[T].to(out).build(schema)

    messages.foreach(message => avro.write(message))
    avro.close()
    out.toByteArray
  }

  def deserialize[T <: Product : Decoder : SchemaFor](bytes: Array[Byte]): List[T] = {
    val schema = AvroSchema[T]
    val avro = AvroInputStream.binary[T].from(bytes).build(schema)

    avro.iterator.toList
  }
}
