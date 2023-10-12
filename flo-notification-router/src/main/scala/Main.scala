import Actors.Coordinator
import Utils.ApplicationSettings
import akka.actor.{ActorRef, ActorSystem, Props}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.ContentTypes
import akka.http.scaladsl.model.HttpEntity
import akka.http.scaladsl.server.Directives._
import akka.stream.ActorMaterializer
import com.flo.Enums.Services.ServiceController
import com.flo.FloApi.notifications.Delivery
import com.flo.utils.HttpMetrics
import com.typesafe.config.ConfigFactory
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

/**
  * Created by Francisco on 4/30/2016.
  */
object Main extends App with LazyLogging {

  Kamon.start()

  logger.info(s"Service started at UTC : ${DateTime.now(DateTimeZone.UTC)}")





  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("notification-actor-system")
  implicit val materializer = ActorMaterializer()
  // needed for the future flatMap/onComplete in the end
  implicit val executionContext = system.dispatcher

  logger.info("Actor system was created ")

  val conf = ConfigFactory.load()

  val coordinator: ActorRef = system.actorOf(Props[Coordinator])
  coordinator ! ServiceController.START

  val route =
    path("") {
      get {
        complete(HttpEntity(contentType = ContentTypes.`text/html(UTF-8)`, "<h1>OK</h1>"))
      }
    }


  val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", 8000)

}
