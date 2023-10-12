package com.flo.notification.router

/**
  * Notification Router's module: binds all application modules together.
  * @note IMPORTANT! THE ORDER IN WHICH MODULES ARE MIXED-IN IS IMPORTANT, AS NON-LAZY VALS REQUIRE ALL OF ITS DEPENDENCIES
  *       TO BE PREVIOUSLY INSTANTIATED. SO, MODULES THAT COME FIRST ARE GENERALLY PROVIDERS OF THOSE BELOW THEM.
  */
object NotificationRouterModule
    extends conf.Module
    with com.flo.util.Module
    with com.flo.akka.Module
    with com.flo.gateway.Module
    with com.flo.notification.scheduling.Module
    with com.flo.scheduler.Module
    with com.flo.notification.sdk.Module
    with com.flo.notification.kafka.Module
    with com.flo.notification.sender.Module
    with com.flo.voice.Module
    with com.flo.localization.Module
    with server.Module
    with core.delivery.Module
    with core.filter.Module
    with core.Module
