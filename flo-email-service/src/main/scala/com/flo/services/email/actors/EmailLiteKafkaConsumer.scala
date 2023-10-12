package com.flo.services.email.actors

import akka.actor.Props
import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.communication.IKafkaConsumer
import com.flo.services.email.services.KafkaActorConsumer

class EmailLiteKafkaConsumer(
	                            kafkaConsumer: IKafkaConsumer,
	                            deserializer: String => EmailFeatherMessage,
	                            filterTimeInSeconds: Int
                            ) extends KafkaActorConsumer[EmailFeatherMessage](kafkaConsumer, deserializer, filterTimeInSeconds) {
	log.info("EmailLiteKafkaConsumer  initialized")
	val flostOffice = context.actorOf(Props[FlostOffice])

	def consume(kafkaMessage: EmailFeatherMessage): Unit = {
		flostOffice ! kafkaMessage
	}
}

object EmailLiteKafkaConsumer {
	def props(
		         kafkaConsumer: IKafkaConsumer,
		         deserializer: String => EmailFeatherMessage,
		         filterTimeInSeconds: Int
	         ): Props = Props(classOf[EmailLiteKafkaConsumer], kafkaConsumer, deserializer, filterTimeInSeconds)
}