package com.flo.puck.util

trait Module {
  def generateUuid: String = java.util.UUID.randomUUID().toString
}
