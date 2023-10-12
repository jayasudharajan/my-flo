package com.flo.puck.akka

import akka.actor.ActorSystem

trait Module {
  // Provides
  val actorSystem: ActorSystem             = ActorSystem("flo-puck-service")
}
