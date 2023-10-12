package flo.services

import java.util.UUID

case class Location(id: UUID, devices: Seq[Device])
