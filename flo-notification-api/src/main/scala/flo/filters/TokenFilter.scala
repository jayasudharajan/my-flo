package flo.filters

import com.twitter.finagle.{Service, SimpleFilter}
import com.twitter.finagle.http.{Request, Response}
import com.twitter.inject.requestscope.FinagleRequestScope
import com.twitter.util.Future
import flo.services.{GatewayService, GatewayServiceFactory}
import javax.inject.{Inject, Singleton}

@Singleton
class TokenFilter @Inject()(
    finagleRequestScope: FinagleRequestScope,
    gatewayServiceFactory: GatewayServiceFactory,
) extends SimpleFilter[Request, Response] {

  def apply(request: Request, service: Service[Request, Response]): Future[Response] = {
    val gatewayService = gatewayServiceFactory.create(getTokenFromHeader(request).getOrElse(""))

    finagleRequestScope.seed[GatewayService](gatewayService)
    service(request)
  }

  def getTokenFromHeader(request: Request): Option[String] =
    if (request.headerMap.contains("Authorization"))
      Some(request.headerMap("Authorization"))
    else
      None
}
