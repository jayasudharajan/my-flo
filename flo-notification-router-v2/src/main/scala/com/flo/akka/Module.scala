package com.flo.akka

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer

trait Module {
  // Provides
  val actorSystem: ActorSystem             = ActorSystem("flo-notification-router-v2")
  val actorMaterializer: ActorMaterializer = ActorMaterializer()(actorSystem)
}
