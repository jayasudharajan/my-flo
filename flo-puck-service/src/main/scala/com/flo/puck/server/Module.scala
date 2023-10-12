package com.flo.puck.server

import java.time.Duration

import akka.actor.ActorSystem
import com.flo.logging.logbookFor
import com.flo.puck.conf._
import com.flo.puck.core.api.PuckTelemetryReportBuilder
import com.flo.puck.server.conf.ServerConfig
import com.typesafe.config.Config
import perfolation._

import scala.concurrent.ExecutionContext

trait Module {
  import Module.log

  // Requires
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def buildPuckTelemetryReport: PuckTelemetryReportBuilder

  // Private
  private val serverConfig = appConfig.as[ServerConfig]("server")
  private val server = new HttpServer(serverConfig)(buildPuckTelemetryReport)(defaultExecutionContext, actorSystem)

  server.start().foreach { _ =>
    log.info(p"Server listening on port ${serverConfig.port}...")
  }(defaultExecutionContext)

  sys.addShutdownHook({
    server.stop(Duration.ofSeconds(10))
  })
}

object Module {
  private val log = logbookFor(getClass)
}
