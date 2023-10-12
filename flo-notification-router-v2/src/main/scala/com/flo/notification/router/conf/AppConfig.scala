package com.flo.notification.router.conf

import com.typesafe.config.{Config, ConfigFactory}

/**
  * Singleton representing the application's config.
  */
private[conf] object AppConfig {

  private val config = ConfigFactory.load()

  /**
    * Returns the application's config.
    */
  def appConfig: Config = config.getConfig("notification-router")

  def rootConfig: Config = config
}
