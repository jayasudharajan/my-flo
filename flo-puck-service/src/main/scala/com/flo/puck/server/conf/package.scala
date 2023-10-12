package com.flo.puck.server

package object conf {
  private[server] case class ServerConfig(port: Int, healthCheckSegment: String)
}
