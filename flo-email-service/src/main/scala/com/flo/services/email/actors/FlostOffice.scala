package com.flo.services.email.actors

import akka.actor.{Actor, ActorLogging, Props}
import akka.stream.ActorMaterializer
import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.Models.KafkaMessages.V2._
import argonaut.Argonaut._
import com.flo.services.email.models.ActorEmailMessage
import com.flo.services.email.models.SendWithUs._
import com.flo.services.email.services.{EmailClient, ValidationService}
import com.flo.services.email.services.v2.EmailService
import com.flo.services.email.utils.ApplicationSettings
import org.joda.time.format.DateTimeFormat

class FlostOffice extends Actor with ActorLogging {
  implicit val materializer = ActorMaterializer()(context)
  implicit val executionContext = context.dispatcher
  implicit val system = context.system

  val emailService = new EmailService()
  val emailClient = new EmailClient(ApplicationSettings.sendWithUs.apiKey)
  val validationService = new ValidationService()

  def receive = {
    case emailFeatherMsg: EmailFeatherMessage =>
      log.info("Flo Post Office opened for business")
      validationService.emailFeatherMessage(emailFeatherMsg)

      log.info(s"Trying to send email id ${emailFeatherMsg.id} meta: ${emailFeatherMsg.emailMetaData.getOrElse("").toString} from app ${emailFeatherMsg.clientAppName}")
      emailFeatherMsg.recipients.foreach(recipient => {

        val msg = ActorEmailMessage(
          templateId = recipient.sendWithUsData.templateId,
          recipientMap = emailService.getRecipientMap(recipient),
          senderMap = emailService.getSenderMap(emailFeatherMsg.sender),
          emailTemplateData = emailService.getJavaMaps(recipient.sendWithUsData.emailTemplateData),
          espAccount = recipient.sendWithUsData.espAccount,
          webHook = emailFeatherMsg.webHook
        )
        emailClient.send(msg)
      })

    case emailWeeklyReport: EmailFeatherMessageV2 =>
      log.info("Flo Post Office opened for business")
      validationService.emailFeatherMessageV2(emailWeeklyReport)
      log.info(s"Trying to send email id ${emailWeeklyReport.id} meta: ${emailWeeklyReport.emailMetaData.getOrElse("").toString} from app ${emailWeeklyReport.clientAppName}")


      emailWeeklyReport.recipients.foreach(recipient => {

        val m = SendRequestWeeklyEmails(
          templateId = recipient.sendWithUsData.templateId,
          recipient = Recipient(
            name = Some(recipient.name.getOrElse(recipient.emailAddress)),
            address = recipient.emailAddress
          ),
          sender = emailService.getSender(emailWeeklyReport),
          templateData = generateSortedWRD(recipient.sendWithUsData.emailTemplateData),
          cc = None,
          bcc = None,
          locale = None,
          espAccount = recipient.sendWithUsData.espAccount,
          versionName = None
        )

        val swu = context.actorOf(Props(new SendWithUsActor(context.system, materializer)))
        swu ! PostRequestInfo(
          postBody = m.asJson.nospaces.toString,
          metaInfo = emailWeeklyReport.emailMetaData
        )

      })
    case jsonEmail: EmailFeatherMessageV4 => {
      log.info("Flo Post Office opened for business for json email ")
      log.info(s"Trying to send email id ${jsonEmail.id} meta: ${jsonEmail.emailMetaData.getOrElse("").toString} from app ${jsonEmail.clientAppName}")

      jsonEmail.recipients.foreach(recipient => {

        val request = SendRequestEmailsJson(
          recipient.sendWithUsData.templateId,
          Recipient(
            name = Some(recipient.name.getOrElse(recipient.emailAddress)),
            address = recipient.emailAddress
          ),
          recipient.sendWithUsData.emailTemplateData.data,
          None,
          None,
          locale = None,
          espAccount = recipient.sendWithUsData.espAccount,
          versionName = None,
          sender = emailService.getSenderFromKafkaSender(jsonEmail.sender)

        )

        val swu = context.actorOf(Props(new SendWithUsActor(context.system, materializer)))
        swu ! PostRequestInfo(
          postBody = request.asJson.nospaces.toString,
          metaInfo = jsonEmail.emailMetaData
        )
      })

    }


    case nightlyReport: EmailFeatherMessageV3NightlyReport =>

      log.info("Flo Post Office opened for business for nightlyReport ")
      validationService.emailFeatherMessageV3NightlyReport(nightlyReport)
      log.info(s"Trying to send email id ${nightlyReport.id} meta: ${nightlyReport.emailMetaData.getOrElse("").toString} from app ${nightlyReport.clientAppName}")
      nightlyReport.recipients.foreach(recipient => {

        val request = SendRequestNightlyReport(
          templateId = recipient.sendWithUsData.templateId,
          recipient = Recipient(
            name = Some(recipient.name.getOrElse(recipient.emailAddress)),
            address = recipient.emailAddress
          ),
          sender = emailService.getSenderFromKafkaSender(nightlyReport.sender),
          templateData = recipient.sendWithUsData.emailTemplateData,
          cc = None,
          bcc = None,
          locale = None,
          espAccount = recipient.sendWithUsData.espAccount,
          versionName = None
        )
        val swu = context.actorOf(Props(new SendWithUsActor(context.system, materializer)))
        swu ! PostRequestInfo(
          postBody = request.asJson.nospaces.toString,
          metaInfo = nightlyReport.emailMetaData
        )

      })


  }


  private def generateSortedWRD(wrd: WeeklyReportData): WeeklyReportData = {
    val alerts = wrd.data.alerts
    if (alerts.isDefined && alerts.nonEmpty) {
      val formatter = DateTimeFormat.forPattern("MM/dd/yyyy")

      val warningA = alerts.get.warningAlerts
      val sortedWarning = if (warningA.isDefined && warningA.nonEmpty) Some(warningA.get.sortWith((a1, a2) => formatter.parseDateTime(a1.incidentDate.get).getMillis > formatter.parseDateTime(a2.incidentDate.get).getMillis)) else warningA
      val criticalA = alerts.get.criticalAlerts
      val sortedCritical = if (criticalA.isDefined && criticalA.nonEmpty) Some(criticalA.get.sortWith((ca1, ca2) => formatter.parseDateTime(ca1.incidentDate.get).getMillis > formatter.parseDateTime(ca2.incidentDate.get).getMillis)) else criticalA

      WeeklyReportData(
        data = WeeklyReport(
          dates = wrd.data.dates,
          user = wrd.data.user,
          waterConsumption = wrd.data.waterConsumption,
          alerts = Some(Alerts(
            criticalAlerts = sortedCritical,
            warningAlerts = sortedWarning,
            pendingAlerts = alerts.get.pendingAlerts,
            shutOffWaterCount = alerts.get.shutOffWaterCount,
            daysSinceLeak = alerts.get.daysSinceLeak,
            deviceOfflineCount = alerts.get.deviceOfflineCount,
            criticalAlertsCount = alerts.get.criticalAlertsCount,
            warningAlertsCount = alerts.get.warningAlertsCount
          )),
          funFacts = wrd.data.funFacts,
          measurementUnitSystem = wrd.data.measurementUnitSystem,
          averagePressure = wrd.data.averagePressure,
          connectivity = wrd.data.connectivity
        )
      )
    }
    else wrd

  }

}