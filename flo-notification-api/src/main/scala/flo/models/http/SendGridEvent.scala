package flo.models.http

case class SendGridEvent(
    category: Option[String],
    email: String,
    event: String,
    receiptId: String,
    sendAt: Option[Long],
    sgEventId: Option[String],
    sgMessageId: Option[String],
    smtpId: Option[String],
    swuTemplateId: Option[String],
    swuTemplateVersionId: Option[String],
    timestamp: Option[Long]
)
