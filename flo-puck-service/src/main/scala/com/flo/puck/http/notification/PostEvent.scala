package com.flo.puck.http.notification

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import com.flo.logging.logbookFor
import com.flo.puck.http.HttpPost
import com.flo.puck.http.nrv2.AlarmIncident
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class PostEvent(
  serializeAlarmIncident: AlarmIncident => String,
  uri: String
) (implicit ec: ExecutionContext, as: ActorSystem) extends HttpPost[AlarmIncident] {

  import PostEvent.log

  override def apply(alarmIncident: AlarmIncident): Future[Unit] = {
    val entity = serializeAlarmIncident(alarmIncident)

    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = uri,
      entity = HttpEntity(ContentTypes.`application/json`, entity)
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      throw new RuntimeException(p"Error sending incident to Notification API: $alarmIncident", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      res.discardEntityBytes()
      if (res.status != StatusCodes.Accepted)
        throw new RuntimeException(p"Error sending incident for device ${alarmIncident.macAddress}.")
      else
        Future.unit
    }
  }
}

object PostEvent {
  private val log = logbookFor(getClass)
}
