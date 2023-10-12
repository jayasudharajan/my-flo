package com.flo.puck.conf

import com.typesafe.config.Config

trait Module {
  // Provides
  val rootConfig: Config = AppConfig.rootConfig
  val appConfig: Config  = AppConfig.appConfig
}
