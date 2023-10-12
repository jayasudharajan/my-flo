package com.flo.communication.avro

import java.net.InetAddress

trait AvroHelper {
  val bootstrapServers: String
  val groupId: String
  val clientName: String

  protected def getClientId(name: String): String = {
    InetAddress.getLocalHost.getHostName + "-" + name + "-" + java.util.UUID.randomUUID.toString
  }
}
