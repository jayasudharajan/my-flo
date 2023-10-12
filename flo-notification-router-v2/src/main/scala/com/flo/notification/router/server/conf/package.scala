package com.flo.notification.router.server

package object conf {
  private[server] case class ServerConfig(port: Int, healthCheckPath: String)
}
