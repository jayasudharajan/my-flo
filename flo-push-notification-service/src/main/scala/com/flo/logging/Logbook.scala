package com.flo.logging

/**
  * Represents a record of important events in the application's internals.
  */
trait Logbook {
  def trace(message: => String)
  def debug(message: => String)
  def info(message: => String)
  def warn(message: => String)
  def warn(message: => String, cause: => Throwable): Unit
  def error(message: => String): Unit
  def error(message: => String, cause: => Throwable): Unit
}
