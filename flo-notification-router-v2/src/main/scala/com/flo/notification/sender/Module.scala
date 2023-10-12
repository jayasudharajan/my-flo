package com.flo.notification.sender

import java.time.{LocalDateTime, OffsetDateTime, ZoneOffset}

import akka.http.scaladsl.model.{ContentTypes, HttpResponse}
import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.logging.logbookFor
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.delivery.KafkaSender
import com.flo.notification.sdk.delivery.PushNotification
import com.flo.notification.sender.Module.log
import com.typesafe.config.Config
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

trait Module {
  // Requires
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def scheduleKafkaMessage(id: String, topic: String, message: String, target: LocalDateTime): Future[Unit]
  def scheduleHttpMessage(id: String,
                          method: String,
                          url: String,
                          contentType: String,
                          body: String,
                          target: LocalDateTime): Future[Unit]
  def sendToEmailGateway: EmailFeatherMessage => Future[HttpResponse]
  def serializeVoiceCall: VoiceCall => String
  def serializeEmail: EmailFeatherMessage => String
  def serializePushNotification: PushNotification => String
  def serializeSms: Sms => String
  def sendToKafka: KafkaSender

  // Private
  private val voiceTopic = appConfig.as[String]("voice.topic")
  private val smsTopic   = appConfig.as[String]("sms.topic")
  private val pushTopic  = appConfig.as[String]("push.topic")

  private val emailGatewayUrl         = appConfig.as[String]("email.email-gateway-url")
  private val emailGatewayQueuePath   = appConfig.as[String]("email.email-gateway-url-queue-path")
  private val emailGatewayQueueMethod = appConfig.as[String]("email.email-gateway-url-queue-method")

  private def offsetDateTimeToUtc(dateTime: OffsetDateTime): LocalDateTime =
    dateTime.atZoneSameInstant(ZoneOffset.UTC).toLocalDateTime

  // Provides
  val voiceCallSender: VoiceCallSender = (id: String, voiceCall: VoiceCall, maybeSchedule: Option[OffsetDateTime]) => {
    val message = serializeVoiceCall(voiceCall)
    val target = maybeSchedule
      .map(offsetDateTimeToUtc)
      .getOrElse {
        LocalDateTime.now(ZoneOffset.UTC).plusSeconds(30)
      }

    log.debug(p"Scheduling voice call with id $id to be sent at $target")
    scheduleKafkaMessage(id, voiceTopic, message, target)
  }

  val emailSender: EmailSender = (id: String, email: EmailFeatherMessage, maybeSchedule: Option[OffsetDateTime]) => {
    maybeSchedule match {
      case Some(s) =>
        val target  = offsetDateTimeToUtc(s)
        val message = serializeEmail(email)

        log.debug(p"Scheduling email with id $id to be sent at $target")
        scheduleHttpMessage(
          id = id,
          method = emailGatewayQueueMethod,
          url = p"$emailGatewayUrl$emailGatewayQueuePath",
          contentType = ContentTypes.`application/json`.toString(),
          body = message,
          target = target
        )

      case None => sendToEmailGateway(email).map(_ => ())(defaultExecutionContext)
    }
  }

  val pushNotificationSender: PushNotificationSender =
    (id: String, pushNotification: PushNotification, maybeSchedule: Option[OffsetDateTime]) => {
      val message = serializePushNotification(pushNotification)
      maybeSchedule match {
        case Some(s) =>
          val target = offsetDateTimeToUtc(s)
          log.debug(p"Scheduling push with id $id to be sent at $target")
          scheduleKafkaMessage(id, pushTopic, message, target)

        case None => sendToKafka(pushTopic, message)
      }
    }

  val smsSender: SmsSender = (id: String, sms: Sms, maybeSchedule: Option[OffsetDateTime]) => {
    val message = serializeSms(sms)
    maybeSchedule match {
      case Some(s) =>
        val target = offsetDateTimeToUtc(s)
        log.debug(p"Scheduling sms with id $id to be sent at $target")
        scheduleKafkaMessage(id, smsTopic, message, target)

      case None => sendToKafka(smsTopic, message)
    }
  }
}

object Module {
  private val log = logbookFor(getClass)
}
