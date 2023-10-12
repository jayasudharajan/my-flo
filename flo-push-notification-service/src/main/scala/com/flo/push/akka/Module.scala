package com.flo.push.akka

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer

trait Module {
  // Provides
  val actorSystem: ActorSystem             = ActorSystem("flo-push-notification-service")
  val actorMaterializer: ActorMaterializer = ActorMaterializer()(actorSystem)
}
