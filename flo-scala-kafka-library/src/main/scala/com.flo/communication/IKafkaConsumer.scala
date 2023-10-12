package com.flo.communication

trait IKafkaConsumer {
  def consume[T <: AnyRef: Manifest](deserializer: String => T, processor: TopicRecord[T] => Unit): Unit
  def pause(): Unit
  def resume(): Unit
  def isPaused(): Boolean
  def shutdown(): Unit
}
