package com.flo.push.core.api

trait Consumer[P] {
  def start(processor: P): Unit

  def stop(): Unit
}
