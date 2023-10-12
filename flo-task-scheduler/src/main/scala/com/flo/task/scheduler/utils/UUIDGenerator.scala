package com.flo.task.scheduler.utils

trait UUIDGenerator {
  def uuid(): String = java.util.UUID.randomUUID.toString
}
