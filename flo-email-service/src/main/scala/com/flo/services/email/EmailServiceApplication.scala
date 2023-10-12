package com.flo.services.email

import akka.actor.{ActorSystem, OneForOneStrategy, SupervisorStrategy}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import argonaut.Parse
import com.flo.Models.KafkaMessages.V2.MessageWrapper
import com.flo.Models.KafkaMessages.{EmailFeatherMessage, EmailMessage}
import com.flo.communication.KafkaConsumer
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}
import com.flo.services.email.actors.{EmailLiteKafkaConsumer, EmailLiteV2KafkaConsumer}
import com.flo.services.email.services.{EmailClient, EmailKafkaConsumer}
import com.flo.services.email.utils.ApplicationSettings
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon
import scala.concurrent.duration._


object EmailServiceApplication extends App with LazyLogging {

	Kamon.start()

	//DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
	implicit val system = ActorSystem("email-service-system")
	implicit val materializer = ActorMaterializer()
	implicit val executionContext = system.dispatcher

	logger.info("Actor system was created")

	val cipher = new FLOCipher
	val keyProvider = new S3RSAKeyProvider(
		ApplicationSettings.cipher.keyProvider.bucketRegion,
		ApplicationSettings.cipher.keyProvider.bucketName,
		ApplicationSettings.cipher.keyProvider.keyPathTemplate
	)
	val rotationStrategy = new KeyIdRotationStrategy
	val encryptionPipeline = new EncryptionPipeline(cipher, keyProvider, rotationStrategy)

	val decryptFunction = (message: String) => encryptionPipeline.decrypt(message)

	implicit val kafkaConsumerV1Metrics = Kamon.metrics.entity(
		KafkaConsumerMetrics,
		ApplicationSettings.kafka.topic,
		tags = Map("service-name" -> ApplicationSettings.kafka.groupId)
	)

	val kafkaConsumer = new KafkaConsumer(
		ApplicationSettings.kafka.host,
		ApplicationSettings.kafka.groupId,
		ApplicationSettings.kafka.topic,
		kafkaConsumerV1Metrics,
		messageDecoder = if (ApplicationSettings.kafka.encryption) Some(decryptFunction) else None,
		clientName = Some("email-service"),
		maxPollRecords = ApplicationSettings.kafka.maxPollRecords,
		pollTimeout = ApplicationSettings.kafka.pollTimeout
	)

	implicit val kafkaConsumerV2Metrics = Kamon.metrics.entity(
		KafkaConsumerMetrics,
		ApplicationSettings.kafka.topicV2,
		tags = Map("service-name" -> ApplicationSettings.kafka.groupId)
	)

	val kafkaConsumerLite = new KafkaConsumer(
		ApplicationSettings.kafka.host,
		ApplicationSettings.kafka.groupId,
		ApplicationSettings.kafka.topicV2,
		kafkaConsumerV2Metrics,
		messageDecoder = if (ApplicationSettings.kafka.encryption) Some(decryptFunction) else None,
		clientName = Some("email-service"),
		maxPollRecords = ApplicationSettings.kafka.maxPollRecords,
		pollTimeout = ApplicationSettings.kafka.pollTimeout
	)

	implicit val kafkaConsumerV3Metrics = Kamon.metrics.entity(
		KafkaConsumerMetrics,
		ApplicationSettings.kafka.topicV3,
		tags = Map("service-name" -> ApplicationSettings.kafka.groupId)
	)

	val kafkaConsumerLiteNoEncryption  = new KafkaConsumer(
		ApplicationSettings.kafka.host,
		ApplicationSettings.kafka.groupId,
		ApplicationSettings.kafka.topicV3,
		kafkaConsumerV3Metrics,
		messageDecoder =  None,
		clientName = Some("email-service"),
		maxPollRecords = ApplicationSettings.kafka.maxPollRecords,
		pollTimeout = ApplicationSettings.kafka.pollTimeout
	)

	val emailClient = new EmailClient(ApplicationSettings.sendWithUs.apiKey)
	val deserializer = (x: String) => Parse.decodeOption[EmailMessage](x).get
	val deserializerLite = (kafkaMsg: String) => Parse.decodeOption[EmailFeatherMessage](kafkaMsg).get
	val deserializerLiteV2 = (kafkaMsg: String) => Parse.decodeOption[MessageWrapper](kafkaMsg).get



	val emailKafkaConsumerProps = EmailKafkaConsumer.props(
		kafkaConsumer,
		deserializer,
		emailClient,
		ApplicationSettings.kafka.filterTimeInSeconds
	)
	val emailLiteKafkaConsumerProps = EmailLiteKafkaConsumer.props(
		kafkaConsumerLite,
		deserializerLite,
		ApplicationSettings.kafka.filterTimeInSeconds
	)

	val emailDecryptedLiteKafkaConsumerProps = EmailLiteV2KafkaConsumer.props(
		kafkaConsumerLiteNoEncryption,
		deserializerLiteV2,
		ApplicationSettings.kafka.filterTimeInSeconds
	)

	val supervisorLiteDecrypted = BackoffSupervisor.props(
		Backoff.onStop(emailDecryptedLiteKafkaConsumerProps,
			childName = "email-consumer-lite-decrypted",
			minBackoff = 3.seconds,
			maxBackoff = 30.seconds,
			randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
		).withSupervisorStrategy(OneForOneStrategy() {
			case ex =>
				system.log.error("There was an error in KafkaActor", ex)
				SupervisorStrategy.Restart //Here we can add some log or send a notification
		})
	)


	val supervisorLite = BackoffSupervisor.props(
		Backoff.onStop(emailLiteKafkaConsumerProps,
			childName = "email-consumer-lite",
			minBackoff = 3.seconds,
			maxBackoff = 30.seconds,
			randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
		).withSupervisorStrategy(OneForOneStrategy() {
			case ex =>
				system.log.error("There was an error in KafkaActor", ex)
				SupervisorStrategy.Restart //Here we can add some log or send a notification
		})
	)

	val supervisor = BackoffSupervisor.props(
		Backoff.onStop(emailKafkaConsumerProps,
			childName = "email-consumer",
			minBackoff = 3.seconds,
			maxBackoff = 30.seconds,
			randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
		).withSupervisorStrategy(OneForOneStrategy() {
			case ex =>
				system.log.error("There was an error in KafkaActor", ex)
				SupervisorStrategy.Restart //Here we can add some log or send a notification
		})
	)

	system.actorOf(supervisor)
	system.actorOf(supervisorLite)
	system.actorOf(supervisorLiteDecrypted)

	val route =
		path("") {
			get {
				complete(HttpEntity(contentType = ContentTypes.`text/html(UTF-8)`, "<h1>OK</h1>"))
			}
		}


	val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", 8000)
}
