package com.flo.puck.http.gateway

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.headers.RawHeader
import akka.http.scaladsl.model.{HttpMethods, HttpRequest, HttpResponse, StatusCodes}
import akka.http.scaladsl.unmarshalling.Unmarshal
import com.flo.logging.logbookFor
import com.flo.puck.core.api.{Device, DeviceId}
import com.flo.puck.http.HttpGet
import perfolation._

import scala.concurrent.{ExecutionContext, Future}


class GetDeviceById (
  uri: String,
  accessToken: String,
  deserializeDeviceResponse: String => DeviceResponse,
) (implicit ec: ExecutionContext, as: ActorSystem) extends HttpGet[DeviceId, Device] {

  import GetDeviceById.log

  override def apply(deviceId: DeviceId): Future[Device] = {
    val httpRequest = HttpRequest(
      method = HttpMethods.GET,
      uri = uri.replace(":id", deviceId),
      headers = List(RawHeader("Authorization", accessToken))
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")

    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      log.error(s"Error Retrieving device data for device: $deviceId.", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      if (res.status == StatusCodes.NotFound) {
        res.discardEntityBytes()
        sys.error(s"Device not found: $deviceId")
      } else {
        val eventualJson = Unmarshal(res.entity).to[String]
        eventualJson.map { json =>
          deserializeDeviceResponse(json).toModel()
        }
      }
    }
  }
}

object GetDeviceById {
  private val log = logbookFor(getClass)
}