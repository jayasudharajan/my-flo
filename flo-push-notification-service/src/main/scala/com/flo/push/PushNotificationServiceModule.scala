package com.flo.push

/**
 * Push Notification Service's module: binds all application modules together.
 * @note IMPORTANT! THE ORDER IN WHICH MODULES ARE MIXED-IN IS IMPORTANT, AS NON-LAZY VALS REQUIRE ALL OF ITS DEPENDENCIES
 *       TO BE PREVIOUSLY INSTANTIATED. SO, MODULES THAT COME FIRST ARE GENERALLY PROVIDERS OF THOSE BELOW THEM.
 */
object PushNotificationServiceModule
    extends conf.Module
    with akka.Module
    with scheduling.Module
    with kafka.Module
    with sdk.Module
    with aws.sns.Module
    with http.Module
    with core.Module
    with server.Module
