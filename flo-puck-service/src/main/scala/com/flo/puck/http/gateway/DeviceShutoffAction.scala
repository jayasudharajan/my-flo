package com.flo.puck.http.gateway

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.http.scaladsl.model.headers.RawHeader
import com.flo.logging.logbookFor
import com.flo.puck.core.api.DeviceId
import com.flo.puck.http.HttpPost
import perfolation._

import scala.concurrent.{ExecutionContext, Future}


class DeviceShutoffAction(
  uri: String,
  accessToken: String,
  serializeShutoffPayload: DeviceShutoffPayload => String,
)(implicit ec: ExecutionContext, as: ActorSystem) extends HttpPost[DeviceId] {

  import DeviceShutoffAction.log

  override def apply(deviceId: DeviceId): Future[Unit] = {
    val entity = serializeShutoffPayload(DeviceShutoffPayload(
      Some(Valve(target = Some(Close), lastKnown = None))
    ))

    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = uri.replace(":id", deviceId),
      entity = HttpEntity(ContentTypes.`application/json`, entity),
      headers = List(RawHeader("Authorization", accessToken))
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")

    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      throw new RuntimeException(p"Error trying to shutoff device with id: $deviceId.", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      res.discardEntityBytes()
      if (res.status == StatusCodes.NotFound) {
        sys.error(p"Device not found: $deviceId")
      } else {
        log.info(p"Shutoff action successfully sent to device id: $deviceId")
        Future.unit
      }
    }
  }
}

object DeviceShutoffAction {
  private val log = logbookFor(getClass)
}
