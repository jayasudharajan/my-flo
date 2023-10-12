package com.flo.puck.http.notification


import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{HttpMethods, HttpRequest, HttpResponse, StatusCodes}
import akka.http.scaladsl.unmarshalling.Unmarshal
import com.flo.logging.logbookFor
import com.flo.puck.core.api.DeviceId
import com.flo.puck.http.HttpGet
import com.flo.puck.http.nrv2.AlarmEventResponse
import perfolation._
import com.flo.puck.core.api.AlarmEvent

import scala.concurrent.{ExecutionContext, Future}

class GetEvent(
  uri: String,
  deserializeEvents: String => AlarmEventResponse
) (implicit ec: ExecutionContext, as: ActorSystem) extends HttpGet[DeviceId, List[AlarmEvent]] {

  import GetEvent.log

  override def apply(deviceId: String): Future[List[AlarmEvent]] = {

    val httpRequest = HttpRequest(
      method = HttpMethods.GET,
      uri = uri + "?deviceId=" + deviceId + "&status=triggered"
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      throw new RuntimeException(s"Error retrieving events for device id: $deviceId.", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      if (res.status == StatusCodes.NotFound) {
        res.discardEntityBytes()
        Future.successful(List())
      } else {
        val eventualJson = Unmarshal(res.entity).to[String]
        eventualJson.map { json =>
          val eventsResponse = deserializeEvents(json)
          eventsResponse.items
        }
      }
    }
  }
}

object GetEvent {
  private val log = logbookFor(getClass)
}
