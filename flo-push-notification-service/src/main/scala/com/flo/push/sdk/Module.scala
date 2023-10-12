package com.flo.push.sdk

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsGrantInfo, FloTokenProviders, OAuth2AuthProvider}
import com.flo.FloApi.v2.{AppDeviceNotificationInfoEnpoints, NotificationTokenEndpoints => NotificationTokenEndpointsV2}
import com.flo.FloApi.v3.{NotificationTokenEndpoints => NotificationTokenEndpointsV3}
import com.flo.push.core.api.NotificationTokenRetriever
import com.flo.utils.{HttpMetrics, IHttpMetrics}
import kamon.Kamon

import scala.concurrent.ExecutionContext

trait Module {

  // Requires
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer

  // Private
  private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> "flo-push-notification-service")
  )

  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(actorSystem, actorMaterializer, httpMetrics)
  private val authProvider = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)

  private val notificationTokenEndpointsV2 =
    new NotificationTokenEndpointsV2(authProvider)(actorSystem, actorMaterializer, httpMetrics)
  private val notificationTokenEndpointsV3 =
    new NotificationTokenEndpointsV3(authProvider)(actorSystem, actorMaterializer, httpMetrics)

  private val appDeviceNotificationInfoEndpoints =
    new AppDeviceNotificationInfoEnpoints(authProvider)(actorSystem, actorMaterializer, httpMetrics)

  // Provides
  val retrieveNotificationTokens: NotificationTokenRetriever =
    new RetrieveNotificationTokens(notificationTokenEndpointsV2, notificationTokenEndpointsV3)(defaultExecutionContext)

  val resourceNameService = new ResourceNameService(appDeviceNotificationInfoEndpoints)(defaultExecutionContext)
}
