package com.flo.services.email.actors

import akka.actor.Props
import com.flo.Models.KafkaMessages.V2._
import com.flo.communication.IKafkaConsumer
import argonaut._
import argonaut.Argonaut._
import com.flo.services.email.services.KafkaActorConsumer

class EmailLiteV2KafkaConsumer(
                                kafkaConsumer: IKafkaConsumer,
                                deserializer: String => MessageWrapper,
                                filterTimeInSeconds: Int
                              ) extends KafkaActorConsumer[MessageWrapper](kafkaConsumer, deserializer, filterTimeInSeconds) {
  log.info("EmailLiteV2KafkaConsumer  initialized")
  val flostOffice = context.actorOf(Props[FlostOffice])

  def consume(kafkaMessage: MessageWrapper): Unit = {
    val info = if (kafkaMessage.requestInfo.isDefined && kafkaMessage.requestInfo.nonEmpty) kafkaMessage.requestInfo.get.asJson.nospaces else "request info N/A"
    log.info(s"processing message: $info")
    kafkaMessage.version match {
      case 1 => //weekly report
        try {
          val message = Parse.decodeOption[EmailFeatherMessageV2](kafkaMessage.message)

          flostOffice ! message.getOrElse(throw new Exception("deserialization error "))

        }
        catch {
          case (ex) =>
            log.error(ex, s"deserializing message: $info")
        }

      case 2 =>
        try {
          Parse.decodeOption[EmailFeatherMessageV4JsonString](kafkaMessage.message) match {

            case Some(message) => flostOffice ! EmailRecipientV4JsonStringToJson(message)

            case None => log.error(s"deserializing message: $info ")

          }


        }
        catch {
          case (ex) =>
            log.error(ex, s"deserializing message: $info")
        }
      case 5000 => //Nightly Report
        try {
          val msgNr = Parse.decodeOption[EmailFeatherMessageV3NightlyReport](kafkaMessage.message)
          flostOffice ! msgNr.getOrElse(throw new Exception("deserialization error nightly report"))
        }
        catch {
          case (ex) =>
            log.error(ex, s"deserializing message: $info")
        }
    }

  }

  private def EmailRecipientV4JsonStringToJson(message: EmailFeatherMessageV4JsonString): EmailFeatherMessageV4 = {
    EmailFeatherMessageV4(
      id = message.id,
      emailMetaData = message.emailMetaData,
      clientAppName = message.clientAppName,
      timeStamp = message.timeStamp,
      sender = message.sender,
      recipients = jsonStringToJson(message.recipients),
      webHook = message.webHook
    )
  }

  private def jsonStringToJson(recipients: Set[EmailRecipientV4JsonString]): (Set[EmailRecipientV4]) = {
    var sMessages = Set[EmailRecipientV4]()
    recipients.foreach(r => {
      sMessages += EmailRecipientV4(
        name = r.name,
        emailAddress = r.emailAddress,
        sendWithUsData = SendWithUsDataJson(
          r.sendWithUsData.templateId,
          r.sendWithUsData.espAccount,
          EmailTemplateData(data = Parse.decodeOption[Json](r.sendWithUsData.emailTemplateData.data).get)
        )
      )

    })
    sMessages
  }


}

object EmailLiteV2KafkaConsumer {
  def props(
             kafkaConsumer: IKafkaConsumer,
             deserializer: String => MessageWrapper,
             filterTimeInSeconds: Int
           ): Props = Props(classOf[EmailLiteV2KafkaConsumer], kafkaConsumer, deserializer, filterTimeInSeconds)
}




