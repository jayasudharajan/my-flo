package flo

import com.jakehschwartz.finatra.swagger.DocsController
import com.twitter.finagle.http.{Request, Response}
import com.twitter.finatra.http.HttpServer
import com.twitter.finatra.http.filters.{LoggingMDCFilter, TraceIdMDCFilter}
import com.twitter.finatra.http.routing.HttpRouter
import com.twitter.inject.requestscope.FinagleRequestScopeFilter
import com.twitter.util.Var
import flo.controllers.{AdminController, FilterController, NotificationController}
import flo.filters.{CommonFilters, TokenFilter}
import flo.modules._
import flo.services.{IllegalArgumentExceptionMapper, ValidationExceptionMapper}
import flo.util.ConfigUtils
import monix.execution.Scheduler
import monix.execution.schedulers.SchedulerService
object ServerMain extends Application

class Application extends HttpServer {
  val health = Var("good")

  implicit lazy val scheduler: SchedulerService = Scheduler.io("flo")

  override protected def modules =
    Seq(AkkaModule, ServiceSwaggerModule, ServiceModule, TokenModule)

  override def jacksonModule = CustomJacksonModule

  override def defaultHttpPort = s":${ConfigUtils.finatra.httpPort}"

  override def defaultHttpsPort = s":${ConfigUtils.finatra.httpsPort}"

  override val name = "flo"

  override def configureHttp(router: HttpRouter): Unit =
    router
      .filter[LoggingMDCFilter[Request, Response]]
      .filter[TraceIdMDCFilter[Request, Response]]
      .filter[CommonFilters]
      .filter[FinagleRequestScopeFilter[Request, Response]]
      .filter[TokenFilter]
      .add[DocsController]
      .add[NotificationController]
      .add[FilterController]
      .add[AdminController]
      .exceptionMapper[ValidationExceptionMapper]
      .exceptionMapper[IllegalArgumentExceptionMapper]
}
