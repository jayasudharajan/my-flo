package com.flo.notification.router.server

import java.net.InetSocketAddress
import java.time.Duration

import com.flo.notification.router.server.conf.ServerConfig
import com.sun.net.httpserver.{HttpExchange, HttpServer}

class BasicHttpServer(serverConfig: ServerConfig) {
  private val SystemDefaultBacklog = 0
  private val NoBody               = -1L

  private val server = HttpServer.create(new InetSocketAddress(serverConfig.port), SystemDefaultBacklog)
  server.createContext(serverConfig.healthCheckPath, httpHandler)
  server.setExecutor(null)

  def start(): Unit = server.start()

  def stop(wait: Duration): Unit = server.stop(wait.getSeconds.toInt)

  private def httpHandler(httpExchange: HttpExchange): Unit = httpExchange.sendResponseHeaders(200, NoBody)
}
