package com.flo.push.http

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.stream.ActorMaterializer
import com.flo.logging.logbookFor
import com.flo.push.conf._
import com.flo.push.core.api.{IncidentId, MarkAsSent, UserId}
import com.flo.push.http.conf.HttpConfig
import com.typesafe.config.Config
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

trait Module {
  import Module.log

  // Requires
  def appConfig: Config
  implicit def defaultExecutionContext: ExecutionContext
  implicit def actorSystem: ActorSystem
  implicit def actorMaterializer: ActorMaterializer

  // Privates
  private val httpConfig = appConfig.as[HttpConfig]("http")

  // Provides
  val markNotificationAsSent: MarkAsSent = (userId: UserId, incidentId: IncidentId) => {
    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = p"${httpConfig.notificationApi.baseUri}${httpConfig.notificationApi.statusPath}"
        .replace(":userId", userId)
        .replace(":incidentId", incidentId),
      entity = HttpEntity(ContentTypes.`application/json`, p"""{"status":"sent"}""")
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    Http().singleRequest(httpRequest).map(_ => ())
  }
}

object Module {
  private val log = logbookFor(getClass)
}
