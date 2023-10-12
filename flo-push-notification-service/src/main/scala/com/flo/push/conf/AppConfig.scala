package com.flo.push.conf

import com.typesafe.config.{Config, ConfigFactory}

/**
  * Singleton representing the application's config.
  */
private[conf] object AppConfig {

  private val config = ConfigFactory.load()

  /**
    * Returns the application's config.
    */
  def appConfig: Config = config.getConfig("push-notification-service")

  def rootConfig: Config = config
}
