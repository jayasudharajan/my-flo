package com.flo.scheduler

import java.time.LocalDateTime

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.http.scaladsl.unmarshalling.Unmarshaller
import akka.pattern.RetrySupport
import akka.stream.ActorMaterializer
import com.flo.logging.logbookFor
import com.flo.notification.router.conf._
import com.flo.scheduler.Module.log
import com.typesafe.config.Config
import io.circe.syntax._
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

trait Module {
  // Requires
  def rootConfig: Config
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer
  def defaultExecutionContext: ExecutionContext

  // Private
  private val taskSchedulerUrl = rootConfig.as[String]("task-scheduler.url")

  // Provides
  def scheduleKafkaMessage(id: String, topic: String, message: String, target: LocalDateTime): Future[Unit] = {
    import circe._
    val kafkaTask = KafkaTask(
      id = id,
      schedule = FixedDateSchedule(config = FixedDateScheduleConfig(target = target)),
      transport = KafkaTransport(
        payload = KafkaTransportPayload(
          topic = topic,
          message = message
        )
      )
    )
    val entity = kafkaTask.asJson.noSpaces

    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = p"$taskSchedulerUrl/tasks",
      entity = HttpEntity(ContentTypes.`application/json`, entity)
    )

    log.debug(p"Scheduling kafka task $id -> topic: $topic")
    RetrySupport
      .retry[HttpResponse](
        attempt = () => {
          Http()(actorSystem)
            .singleRequest(httpRequest)
            .map {
              case r if r.status.isSuccess() => r
              case r =>
                throw new Exception(
                  p"Error while scheduling kafka task $id - status: ${r.status.value} - body: ${Unmarshaller
                    .stringUnmarshaller(r.entity)(defaultExecutionContext, actorMaterializer)}"
                )
            }(defaultExecutionContext)
        },
        attempts = 3,
        delay = 1.seconds
      )(defaultExecutionContext, actorSystem.scheduler)
      .map(_ => ())(defaultExecutionContext)
  }

  def scheduleHttpMessage(id: String,
                          method: String,
                          url: String,
                          contentType: String,
                          body: String,
                          target: LocalDateTime): Future[Unit] = {
    import Module.log
    import circe._
    val httpTask = HttpTask(
      id = id,
      schedule = FixedDateSchedule(config = FixedDateScheduleConfig(target = target)),
      transport = HttpTransport(
        payload = HttpTransportPayload(
          method = method,
          url = url,
          contentType = contentType,
          body = body
        )
      )
    )
    val entity = httpTask.asJson.noSpaces

    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = p"$taskSchedulerUrl/tasks",
      entity = HttpEntity(ContentTypes.`application/json`, entity)
    )

    log.debug(p"Scheduling http task $id -> $method $url")
    RetrySupport
      .retry[HttpResponse](
        attempt = () => {
          Http()(actorSystem)
            .singleRequest(httpRequest)
            .map {
              case r if r.status.isSuccess() => r
              case r =>
                throw new Exception(
                  p"Error while scheduling http task $id - status: ${r.status.value} - body: ${Unmarshaller
                    .stringUnmarshaller(r.entity)(defaultExecutionContext, actorMaterializer)}"
                )
            }(defaultExecutionContext)
        },
        attempts = 3,
        delay = 1.seconds
      )(defaultExecutionContext, actorSystem.scheduler)
      .map(_ => ())(defaultExecutionContext)
  }

  def cancelScheduledTask(id: String): Future[Unit] = {
    val httpRequest = HttpRequest(
      method = HttpMethods.POST,
      uri = p"$taskSchedulerUrl/tasks/$id/cancel"
    )
    log.debug(p"Canceling scheduled task $id")
    RetrySupport
      .retry[HttpResponse](
        attempt = () => {
          Http()(actorSystem)
            .singleRequest(httpRequest)
            .map {
              case r if r.status.isSuccess()       => r
              case r if r.status.intValue() == 404 => r // No failure / No retry. Task was never created.
              case r =>
                throw new Exception(p"Error while canceling task $id - status: ${r.status.value} - body: ${Unmarshaller
                  .stringUnmarshaller(r.entity)(defaultExecutionContext, actorMaterializer)}")
            }(defaultExecutionContext)
        },
        attempts = 3,
        delay = 1.seconds
      )(defaultExecutionContext, actorSystem.scheduler)
      .map(_ => ())(defaultExecutionContext)
  }
}

object Module {
  private val log = logbookFor(getClass)
}
