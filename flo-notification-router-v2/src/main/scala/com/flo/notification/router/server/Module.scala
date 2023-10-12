package com.flo.notification.router.server

import java.time.Duration

import com.flo.notification.router.server.conf.ServerConfig
import com.flo.notification.router.conf._
import com.typesafe.config.Config

import scala.concurrent.{ExecutionContext, Future}

trait Module {
  // Requires
  def appConfig: Config
  def blockableExecutionContext: ExecutionContext

  // Private
  private val serverConfig = appConfig.as[ServerConfig]("server")

  private val server = new BasicHttpServer(serverConfig)
  Future {
    server.start()
  }(blockableExecutionContext)

  sys.addShutdownHook({
    server.stop(Duration.ofSeconds(10))
  })
}
