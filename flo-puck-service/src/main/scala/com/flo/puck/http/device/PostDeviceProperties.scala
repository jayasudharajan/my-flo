package com.flo.puck.http.device

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import com.flo.logging.logbookFor
import com.flo.puck.core.api.MacAddress
import com.flo.puck.http.HttpPost
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class PostDeviceProperties(
  serializeDeviceProperties: DeviceRequest => String,
  uri: String,
  versionAdapter: Int => String,
)(implicit ec: ExecutionContext, as: ActorSystem) extends HttpPost[(MacAddress, PuckData)] {

  import PostDeviceProperties.log

  override def apply(params: (MacAddress, PuckData)): Future[Unit] = {
    val (macAddress, puckData) = params

    val entity = serializeDeviceProperties(DeviceRequest(
      puckData.telemetry.map(_.raw),
      puckData.telemetry.flatMap(_.properties.fwVersion.map(versionAdapter)),
      puckData.audioSettings
    ))

    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = uri.replace(":id", macAddress),
      entity = HttpEntity(ContentTypes.`application/json`, entity)
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")

    val eventualResponse: Future[HttpResponse] = Http().singleRequest(httpRequest)

    eventualResponse.map { r =>
      r.discardEntityBytes()
      log.debug(p"Successfully sent ${httpRequest.method} ${httpRequest.uri.toString()}")
    }
  }

}

object PostDeviceProperties {
  private val log = logbookFor(getClass)
}
