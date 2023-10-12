package flo.services

import java.util.UUID
import flo.util.TypeConversionImplicits._

case class User(id: UUID, accountId: String, locations: Seq[Location], locale: String) {

  private val deviceToLocationMap = locations.flatMap(l => l.devices.map(d => (d.id -> l))).toMap

  val devices: Seq[Device] = locations.flatMap(_.devices)

  def getLocationByDevice(id: String): Option[Location] =
    deviceToLocationMap.get(id)

}
