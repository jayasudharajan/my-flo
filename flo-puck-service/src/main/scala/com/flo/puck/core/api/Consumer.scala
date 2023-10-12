package com.flo.puck.core.api

trait Consumer[P] {
  def start(processor: P, r: Option[ResumeOnExceptions] = None): Unit

  def stop(): Unit
}
