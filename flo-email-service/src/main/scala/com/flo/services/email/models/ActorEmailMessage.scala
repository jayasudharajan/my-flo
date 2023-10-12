package com.flo.services.email.models

case class ActorEmailMessage(
												 templateId: String,
												 recipientMap: Map[String, Object],
												 senderMap: Map[String, Object],
												 emailTemplateData: Map[String, Object],
												 espAccount: Option[String],
												 webHook: Option[String]
											 ) {

}
