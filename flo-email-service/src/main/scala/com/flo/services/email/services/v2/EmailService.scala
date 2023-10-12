package com.flo.services.email.services.v2

import com.flo.Models.KafkaMessages.V2.EmailFeatherMessageV2
import com.flo.Models.KafkaMessages.{EmailRecipient, EmailSender, V2}
import com.flo.services.email.models.SendWithUs.Sender
import com.flo.services.email.utils.ApplicationSettings
import scala.collection.JavaConverters._

class EmailService {
	def getRecipientMap(recipient: EmailRecipient): Map[String, Object] = {
		Map(
			"name" -> recipient.name.getOrElse(recipient.emailAddress),
			"address" -> recipient.emailAddress
		)
	}

	def getRecipientMapV2(recipient: V2.EmailRecipient): Map[String, Object] = {
		Map(
			"name" -> recipient.name.getOrElse(recipient.emailAddress),
			"address" -> recipient.emailAddress
		)
	}

	def getSenderMap(emailSender: Option[EmailSender]): Map[String, Object] = emailSender match {
		case Some(sender) =>
			Map(
				"name" -> sender.name.getOrElse(sender.emailAddress),
				"address" -> sender.emailAddress,
				"reply_to" -> sender.replyToAddress.getOrElse(sender.emailAddress)
			)
		case _ =>
			Map(
				"name" -> ApplicationSettings.sendWithUs.name,
				"address" -> ApplicationSettings.sendWithUs.defaultEmailAddress,
				"reply_to" -> ApplicationSettings.sendWithUs.replyToEmailAddress
			)
	}


	def getJavaMaps(mapOfMaps: Map[String, Map[String, String]]): Map[String, Object] = {
		var javaMaps = Map[String, Object]()
		mapOfMaps.foreach(m => {
			javaMaps += (m._1 -> m._2.asJava)
		})
		javaMaps
	}

	def getSender(emailMsg: EmailFeatherMessageV2): Option[Sender] = {
		if (emailMsg.sender.isDefined && emailMsg.sender.nonEmpty) {
			val s = emailMsg.sender.get
			Some(Sender(
				name = s.name.getOrElse(s.emailAddress),
				address = s.emailAddress,
				replyTo = s.replyToAddress.getOrElse(s.emailAddress)
			))
		}
		else {
			Some(Sender(
				name = ApplicationSettings.sendWithUs.name,
				address = ApplicationSettings.sendWithUs.defaultEmailAddress,
				replyTo = ApplicationSettings.sendWithUs.replyToEmailAddress
			))
		}
	}

	def getSenderFromKafkaSender(sender: Option[EmailSender]): Option[Sender] = {
		if (sender.isDefined && sender.nonEmpty) {
			val s = sender.get
			Some(Sender(
				name = s.name.getOrElse(s.emailAddress),
				address = s.emailAddress,
				replyTo = s.replyToAddress.getOrElse(s.emailAddress)
			))
		}
		else {
			Some(Sender(
				name = ApplicationSettings.sendWithUs.name,
				address = ApplicationSettings.sendWithUs.defaultEmailAddress,
				replyTo = ApplicationSettings.sendWithUs.replyToEmailAddress
			))
		}
	}


}

