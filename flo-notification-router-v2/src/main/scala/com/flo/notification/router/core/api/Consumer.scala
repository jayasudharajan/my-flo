package com.flo.notification.router.core.api

trait Consumer[P] {
  def start(processor: P, r: Option[ResumeOnExceptions] = None): Unit

  def stop(): Unit
}
