package com.flo.services.email.models.SendWithUs

import argonaut.Argonaut._
import argonaut._
import com.flo.Models.KafkaMessages.V2.{NightlyReportData, WeeklyReportData}

case class SendRequestWeeklyEmails(
                                    templateId: String,
                                    recipient: Recipient,
                                    templateData: WeeklyReportData,
                                    cc: Option[Set[ExtraEmailsCcAndBcc]],
                                    bcc: Option[Set[ExtraEmailsCcAndBcc]],
                                    sender: Option[Sender],
                                    locale: Option[String],
                                    espAccount: Option[String],
                                    versionName: Option[String]
                                  ) {


}

object SendRequestWeeklyEmails {
  implicit def SendRequestWeeklyEmailsCodecJson: CodecJson[SendRequestWeeklyEmails] = casecodec9(SendRequestWeeklyEmails.apply, SendRequestWeeklyEmails.unapply)(
    "template",
    "recipient",
    "template_data",
    "cc",
    "bcc",
    "sender",
    "locale",
    "esp_account",
    "version_name"
  )
}

case class SendRequestEmailsJson(
                                  templateId: String,
                                  recipient: Recipient,
                                  templateData: Json,
                                  cc: Option[Set[ExtraEmailsCcAndBcc]],
                                  bcc: Option[Set[ExtraEmailsCcAndBcc]],
                                  sender: Option[Sender],
                                  locale: Option[String],
                                  espAccount: Option[String],
                                  versionName: Option[String]
                                ) {


}

object SendRequestEmailsJson {
  implicit def SendRequestEmailsJsonCodecJson: CodecJson[SendRequestEmailsJson] = casecodec9(SendRequestEmailsJson.apply,
    SendRequestEmailsJson.unapply)(
    "template",
    "recipient",
    "template_data",
    "cc",
    "bcc",
    "sender",
    "locale",
    "esp_account",
    "version_name"
  )
}

case class SendRequestNightlyReport(
                                     templateId: String,
                                     recipient: Recipient,
                                     templateData: NightlyReportData,
                                     cc: Option[Set[ExtraEmailsCcAndBcc]],
                                     bcc: Option[Set[ExtraEmailsCcAndBcc]],
                                     sender: Option[Sender],
                                     locale: Option[String],
                                     espAccount: Option[String],
                                     versionName: Option[String]
                                   ) {


}

object SendRequestNightlyReport {
  implicit def SendRequestNightlyReportEmailsCodecJson: CodecJson[SendRequestNightlyReport] = casecodec9(SendRequestNightlyReport.apply, SendRequestNightlyReport.unapply)(
    "template",
    "recipient",
    "template_data",
    "cc",
    "bcc",
    "sender",
    "locale",
    "esp_account",
    "version_name"
  )
}