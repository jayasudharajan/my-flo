package com.flo.puck.http.device

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{HttpMethods, HttpRequest, HttpResponse, StatusCodes}
import akka.http.scaladsl.unmarshalling.Unmarshal
import com.flo.logging.logbookFor
import com.flo.puck.core.api.{ActionRule, DeviceId}
import com.flo.puck.http.HttpGet
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class GetActionRules(
  uri: String,
  deserializeActionRules: String => ActionRulesResponse
) (implicit ec: ExecutionContext, as: ActorSystem) extends HttpGet[DeviceId, List[ActionRule]] {

  import GetActionRules.log

  override def apply(deviceId: String): Future[List[ActionRule]] = {

    val httpRequest = HttpRequest(
      method = HttpMethods.GET,
      uri = uri.replace(":id", deviceId)
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      throw new RuntimeException(s"Error retrieving action rules for device id: $deviceId.", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      if (res.status == StatusCodes.NotFound) {
        res.discardEntityBytes()
        Future.successful(List())
      } else {
        val eventualJson = Unmarshal(res.entity).to[String]
        eventualJson.map { json =>
          val actionRulesResponse = deserializeActionRules(json)
          actionRulesResponse.actionRules
        }
      }
    }
  }
}

object GetActionRules {
  private val log = logbookFor(getClass)
}
