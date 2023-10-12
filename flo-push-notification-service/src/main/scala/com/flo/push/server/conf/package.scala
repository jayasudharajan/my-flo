package com.flo.push.server

package object conf {
  private[server] case class ServerConfig(port: Int, healthCheckPath: String)
}
