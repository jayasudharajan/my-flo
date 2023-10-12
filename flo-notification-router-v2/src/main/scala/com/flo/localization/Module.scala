package com.flo.localization

import java.time.ZoneId

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.localization.LocalizedApi
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsGrantInfo, FloTokenProviders, OAuth2AuthProvider}
import com.flo.localization.conf.CacheConfig
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.router.conf._
import com.flo.utils.{HttpMetrics, IHttpMetrics}
import com.github.blemale.scaffeine.Scaffeine
import com.typesafe.config.Config
import kamon.Kamon

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  implicit def defaultExecutionContext: ExecutionContext
  def rootConfig: Config
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer

  // Privates
  implicit private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-localization-service",
    tags = Map("service-name" -> "flo-notification-router-v2")
  )
  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(actorSystem, actorMaterializer, httpMetrics)

  private val authProvider = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)

  private val localizationApi = new LocalizedApi()(authProvider)(actorSystem, actorMaterializer, httpMetrics)

  private val defaultDateTimeFormat = rootConfig.as[String]("localization.default-date-time-format")
  private val defaultTimeZone       = rootConfig.as[ZoneId]("localization.default-time-zone")

  private val cacheConfig = rootConfig.as[CacheConfig]("localization.cache")

  private val localizationCache = Scaffeine()
    .recordStats()
    .expireAfterWrite(cacheConfig.expireAfterWrite)
    .maximumSize(cacheConfig.maxSize)
    .build[String, String]

  private val defaultLocalizationService =
    new DefaultLocalizationService(localizationApi, defaultDateTimeFormat, defaultTimeZone)

  // Provides
  val localizationService: LocalizationService =
    new CachedLocalizationService(defaultLocalizationService, localizationCache)
}
