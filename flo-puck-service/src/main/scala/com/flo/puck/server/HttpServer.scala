package com.flo.puck.server

import java.time.Duration

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.http.scaladsl.server.Directives._
import akka.http.scaladsl.server.{MalformedQueryParamRejection, RejectionHandler}
import com.flo.logging.logbookFor
import com.flo.puck.core.api._
import com.flo.puck.server.conf.ServerConfig
import com.flo.puck.server.marshalling._
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

class HttpServer(serverConfig: ServerConfig)
                (buildPuckTelemetryReport: PuckTelemetryReportBuilder)
                (implicit ec: ExecutionContext, as: ActorSystem) {

  import HttpServer.log

  private val badRequestHandler = RejectionHandler.newBuilder()
    .handle {
      case MalformedQueryParamRejection(parameterName, _, _) =>
        complete(HttpResponse(
          entity = HttpEntity(ContentTypes.`application/json`, p"""{"error":"Invalid value for '$parameterName' query parameter."}"""),
          status = StatusCodes.BadRequest
        ))
    }
    .result()

  private val route = concat(
    path(serverConfig.healthCheckSegment) {
      complete((StatusCodes.OK, HttpEntity.Empty))
    },
    handleRejections(badRequestHandler) {
      path("devices" / Segment / "telemetry") { macAddress =>
        get {
          parameters(("interval".as[Interval].?, "timezone".as[TimeZone].?, "startDate".as[StartDate].?, "endDate".as[EndDate].?)) { (maybeInterval, maybeTimeZone, maybeStartDate, maybeEndDate) =>
            import jsonSupport._
            completeOrRecoverWith(buildPuckTelemetryReport(macAddress, maybeInterval, maybeTimeZone, maybeStartDate, maybeEndDate)) { e =>
              log.error("Error building puck telemetry report.", e)
              complete(HttpResponse(
                entity = HttpEntity(ContentTypes.`application/json`, p"""{"error":"Something went wrong."}"""),
                status = StatusCodes.InternalServerError
              ))
            }
          }
        }
      }
    }
  )

  private lazy val eventualBinding = Http().bindAndHandle(route, "0.0.0.0", serverConfig.port)

  def start(): Future[Unit] = eventualBinding.map(_ => ())

  def stop(wait: Duration): Unit = eventualBinding.foreach(_.terminate(FiniteDuration(wait.toNanos, NANOSECONDS)))
}

object HttpServer {
  private val log = logbookFor(getClass)
}
