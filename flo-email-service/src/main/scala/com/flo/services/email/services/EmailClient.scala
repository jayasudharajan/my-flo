package com.flo.services.email.services

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.Enums.Logs.{DeliveryMediumLogSenders, DeliveryMediumLogStatus}
import com.flo.Models.Logs.{EmailDeliveryLog, EmailSendWithUsSendDetails, EmailSendWithUsSendReceipt}
import com.sendwithus.model.SendReceipt
import com.sendwithus.{SendWithUs, SendWithUsSendRequest}
import org.joda.time.{DateTime, DateTimeZone}
import com.typesafe.scalalogging.LazyLogging
import argonaut.Argonaut._
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{EmailDeliveryLogEndpoints, WebhooksEmail}
import com.flo.services.email.models.ActorEmailMessage
import com.flo.services.email.utils.ApplicationSettings
import com.flo.utils.HttpMetrics
import kamon.Kamon
import scala.concurrent.ExecutionContext.Implicits.global
import collection.JavaConverters._
import scala.concurrent.{ExecutionContext, Future}
import scala.collection.convert.Wrappers.MapWrapper

class EmailClient(apiKey: String)(implicit system: ActorSystem, materializer: ActorMaterializer, ec: ExecutionContext)
  extends IEmailClient with LazyLogging {

  val sendWithUsApi: SendWithUs = new SendWithUs(apiKey)
  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val floProxyWebHooksEmail = new WebhooksEmail(clientCredentialsTokenProvider)
  val floEmailLog = new EmailDeliveryLogEndpoints(clientCredentialsTokenProvider)

  def send(email: ActorEmailMessage): Future[SendReceipt] = {
    val tags = email
      .emailTemplateData
      .get("alarm")
      .map(alarm => {
        alarm.asInstanceOf[scala.collection.convert.Wrappers.MapWrapper[String, String]].get("alarm_id")
      })
      .map(x => List(s"alarm_id_${x.toString}"))
      .getOrElse(Nil)
      .toArray

    val request = new SendWithUsSendRequest()
      .setEmailId(email.templateId)
      .setRecipient(email.recipientMap.asJava)
      .setEmailData(email.emailTemplateData.asJava)
      .setSender(email.senderMap.asJava)
      .setEspAccount(email.espAccount.orNull)
      .setTags(tags)

    val sendReceipt = sendWithUsApi.send(request)
    logger.info(s"email sent receipt ${sendReceipt.getReceiptID} ")

    val webHookResult = email.webHook.isDefined match {
      case true =>
        try {
          floProxyWebHooksEmail.Post(email.webHook.get, receiptMapper(sendReceipt))
        }
        catch {
          case e: Throwable => logger.error(s"The following error happened on floProxyWebHooksEmail.Post: ${e.toString}")
            Future(true)
        }

      case false => Future(true)
    }

    val emailDeliveryLog = EmailDeliveryLog(
      id = Some(java.util.UUID.randomUUID().toString),
      createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString),
      sender = Some(DeliveryMediumLogSenders.FLO_NOTIFICATION_ROUTER),
      status = Some(DeliveryMediumLogStatus.SENT),
      data = Some(receiptMapper(sendReceipt).asJson.nospaces)
    )

    val deliveryLogResult = floEmailLog.Post(Some(emailDeliveryLog))

    for {
      r <- webHookResult
      d <- deliveryLogResult
      r <- Future(sendReceipt)
    } yield (sendReceipt)
  }

  private def receiptMapper(receipt: SendReceipt): EmailSendWithUsSendReceipt = {

    EmailSendWithUsSendReceipt(
      receiptId = receipt.getReceiptID,
      emailSendWithUsDetails = EmailSendWithUsSendDetails(
        name = receipt.getEmail.getName,
        versionName = receipt.getEmail.getVersionName,
        locale = receipt.getEmail.getLocale
      )
    )

  }
}



