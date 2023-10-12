package com.flo.services.email.services

import java.security.InvalidParameterException

import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.Models.KafkaMessages.V2.{EmailFeatherMessageV2, EmailFeatherMessageV3NightlyReport}
import com.typesafe.scalalogging.LazyLogging

class ValidationService extends LazyLogging {
	def emailFeatherMessage(msg: EmailFeatherMessage): Boolean = {
		if (msg.recipients.isEmpty) {
			logger.error("found empty recipient")
			throw new InvalidParameterException("recipients cannot be empty")
		}
		msg.recipients.foreach(recipient => {
			if (recipient.emailAddress.isEmpty) {
				logger.error("Found empty recipient email address")
				throw new InvalidParameterException("Found empty recipient email address")
			}
			if (recipient.sendWithUsData.templateId.isEmpty) {
				logger.error("Found empty recipient template id ")
				throw new InvalidParameterException("Found empty recipient template id ")
			}
			if (recipient.sendWithUsData.emailTemplateData.isEmpty) {
				logger.warn("Found empty recipient email send with us data")
				throw new InvalidParameterException("Found empty recipient email send with us data")

			}
		})
		true
	}
	def emailFeatherMessageV2(msg:EmailFeatherMessageV2):Boolean = {
		if (msg.recipients.isEmpty) {
			logger.error("found empty recipient")
			throw new InvalidParameterException("recipients cannot be empty")
		}
		msg.recipients.foreach(recipient => {
			if (recipient.emailAddress.isEmpty) {
				logger.error("Found empty recipient email address")
				throw new InvalidParameterException("Found empty recipient email address")
			}
			if (recipient.sendWithUsData.templateId.isEmpty) {
				logger.error("Found empty recipient template id ")
				throw new InvalidParameterException("Found empty recipient template id ")
			}

		})
		true
	}
	def emailFeatherMessageV3NightlyReport(msg:EmailFeatherMessageV3NightlyReport):Boolean = {
		if (msg.recipients.isEmpty) {
			logger.error("found empty recipient")
			throw new InvalidParameterException("recipients cannot be empty")
		}
		msg.recipients.foreach(recipient => {
			if (recipient.emailAddress.isEmpty) {
				logger.error("Found empty recipient email address")
				throw new InvalidParameterException("Found empty recipient email address")
			}
			if (recipient.sendWithUsData.templateId.isEmpty) {
				logger.error("Found empty recipient template id ")
				throw new InvalidParameterException("Found empty recipient template id ")
			}

		})
		true
	}

}
