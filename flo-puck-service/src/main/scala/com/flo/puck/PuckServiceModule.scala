package com.flo.puck

/**
 * Puck Service's module: binds all application modules together.
 * @note IMPORTANT! THE ORDER IN WHICH MODULES ARE MIXED-IN IS IMPORTANT, AS NON-LAZY VALS REQUIRE ALL OF ITS DEPENDENCIES
 *       TO BE PREVIOUSLY INSTANTIATED. SO, MODULES THAT COME FIRST ARE GENERALLY PROVIDERS OF THOSE BELOW THEM.
 */
object PuckServiceModule
  extends conf.Module
  with com.flo.puck.akka.Module
  with com.flo.puck.scheduling.Module
  with com.flo.puck.util.Module
  with com.flo.puck.kafka.Module
  with com.flo.puck.http.Module
  with com.flo.puck.sql.Module
  with core.report.Module
  with core.trigger.Module
  with core.resolver.Module
  with core.Module
  with server.Module
