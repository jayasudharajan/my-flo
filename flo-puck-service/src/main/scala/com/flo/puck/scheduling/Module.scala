package com.flo.puck.scheduling

import java.time.Clock
import java.util.concurrent.Executors

import akka.actor.ActorSystem

import scala.concurrent.ExecutionContext

trait Module {

  // Requires
  def actorSystem: ActorSystem

  // Provides
  val defaultExecutionContext: ExecutionContext   = actorSystem.dispatcher
  val blockableExecutionContext: ExecutionContext = ExecutionContext.fromExecutor(Executors.newCachedThreadPool())
  val defaultClock: Clock                         = Clock.systemUTC()
}
