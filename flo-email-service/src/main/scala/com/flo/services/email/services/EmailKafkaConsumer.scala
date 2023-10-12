package com.flo.services.email.services

import akka.actor.Props
import com.flo.Models.KafkaMessages.EmailMessage
import com.flo.communication.IKafkaConsumer

import scala.util.Success
import scala.util.Failure
import scala.util.Try

class EmailKafkaConsumer(
	                        kafkaConsumer: IKafkaConsumer,
	                        deserializer: String => EmailMessage,
	                        emailService: IEmailClient,
	                        filterTimeInSeconds: Int
                        )
	extends KafkaActorConsumer[EmailMessage](kafkaConsumer, deserializer, filterTimeInSeconds) {

	log.info("EmailKafkaConsumer started!")


	val emailServiceSupervisor = context.actorOf(
		EmailServiceSupervisor.props(emailService),
		"email-service-supervisor"
	)

	def consume(kafkaMessage: EmailMessage): Unit = {
		Try(EmailTransformations.toActorEmailMessage(kafkaMessage)) match {
			case Success(emailMessage) => emailServiceSupervisor ! emailMessage
			case Failure(ex) => log.error(s"Problem transforming kafka message: ${ex.getMessage}")
		}
	}
}

object EmailKafkaConsumer {
	def props(
		         kafkaConsumer: IKafkaConsumer,
		         deserializer: String => EmailMessage,
		         emailService: IEmailClient,
		         filterTimeInSeconds: Int
	         ): Props = Props(classOf[EmailKafkaConsumer], kafkaConsumer, deserializer, emailService, filterTimeInSeconds)
}