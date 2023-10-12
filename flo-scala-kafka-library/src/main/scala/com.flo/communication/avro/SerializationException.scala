package com.flo.communication.avro

class SerializationException(message: String, cause: Throwable) extends Exception(message, cause)

object SerializationException {
  def consumerDeserializationException(cause: Throwable): SerializationException = {
    new SerializationException("There was a problem while deserializing consumer message", cause)
  }
}