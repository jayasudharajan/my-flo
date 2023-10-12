package com.flo.puck.http.gateway

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.headers.RawHeader
import akka.http.scaladsl.model.{HttpMethods, HttpRequest, HttpResponse, StatusCodes}
import akka.http.scaladsl.unmarshalling.Unmarshal
import com.flo.logging.logbookFor
import com.flo.puck.core.api.{Device, MacAddress}
import com.flo.puck.http.HttpGet
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class GetDeviceByMacAddress (
  uri: String,
  accessToken: String,
  deserializeDeviceResponse: String => DeviceResponse,
) (implicit ec: ExecutionContext, as: ActorSystem) extends HttpGet[MacAddress, Device] {

  import GetDeviceByMacAddress._

  override def apply(macAddress: MacAddress): Future[Device] = {
    val httpRequest = HttpRequest(
      method = HttpMethods.GET,
      uri = p"$uri?macAddress=${macAddress}",
      headers = List(RawHeader("Authorization", accessToken))
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.failed.foreach { e =>
      throw new RuntimeException(p"Error Retrieving device data for device with macAddress: $macAddress.", e)
    }

    eventualResponse.flatMap { res =>
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
      if (res.status == StatusCodes.NotFound) {
        res.discardEntityBytes()
        sys.error(p"Device not found: $macAddress")
      } else {
        val eventualJson = Unmarshal(res.entity).to[String]
        eventualJson.map(json => deserializeDeviceResponse(json).toModel())
      }
    }
  }
}

object GetDeviceByMacAddress {
  private val log = logbookFor(getClass)
}