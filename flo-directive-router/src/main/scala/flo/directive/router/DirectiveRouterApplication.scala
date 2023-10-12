package flo.directive.router

import akka.actor.{ActorSystem, OneForOneStrategy, SupervisorStrategy}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{DirectiveTrackingEndpoints, IcdForcedSystemModesEndpoints}
import com.flo.Models.KafkaMessages._
import com.flo.communication.KafkaConsumer
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}
import com.flo.utils.{FromCamelToSneakCaseSerializer, FromSneakToCamelCaseDeserializer, HttpMetrics}
import com.typesafe.scalalogging.LazyLogging
import flo.directive.router.services.DirectiveKafkaConsumer
import flo.directive.router.utils.{ConfigUtils, MQTTClient, MQTTSecurityProvider}
import kamon.Kamon

import scala.concurrent.duration._

object DirectiveRouterApplication extends App with LazyLogging {

  Kamon.start()

  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("directive-router-system")
  implicit val materializer = ActorMaterializer()
  implicit val executionContext = system.dispatcher

  logger.info("Actor system was created for Directive Router")

  val cipher = new FLOCipher
  val keyProvider = new S3RSAKeyProvider(
    ConfigUtils.cipher.keyProvider.bucketRegion,
    ConfigUtils.cipher.keyProvider.bucketName,
    ConfigUtils.cipher.keyProvider.keyPathTemplate
  )
  val rotationStrategy = new KeyIdRotationStrategy
  val encryptionPipeline = new EncryptionPipeline(cipher, keyProvider, rotationStrategy)
  val decryptFunction = (message: String) => encryptionPipeline.decrypt(message)

  implicit val kafkaConsumerMetrics = Kamon.metrics.entity(
    KafkaConsumerMetrics,
    ConfigUtils.kafka.topic,
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  val kafkaConsumer = new KafkaConsumer(
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId,
    ConfigUtils.kafka.topic,
    kafkaConsumerMetrics,
    messageDecoder = if(ConfigUtils.kafka.encryption) Some(decryptFunction) else None,
    clientName = Some("directive-router"),
    maxPollRecords = ConfigUtils.kafka.maxPollRecords,
    pollTimeout = ConfigUtils.kafka.pollTimeout
  )

  val mqttSecurity = ConfigUtils.mqtt.sslConfiguration.map(x =>
    new MQTTSecurityProvider(
      ConfigUtils.aws.configBucket,
      x
    )
  )

  val mqttClient = new MQTTClient(
    ConfigUtils.mqtt.broker,
    ConfigUtils.mqtt.qos,
    ConfigUtils.mqtt.clientId,
    mqttSecurity
  )

  val deserializer = new FromSneakToCamelCaseDeserializer
  val serializer = new FromCamelToSneakCaseSerializer

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val directiveTrackingEndpoints = new DirectiveTrackingEndpoints(clientCredentialsTokenProvider)
  val systemModesEndpoints = new IcdForcedSystemModesEndpoints(clientCredentialsTokenProvider)

  val directiveConsumerProps = DirectiveKafkaConsumer.props(
    DirectiveKafkaConsumer.DirectiveKafkaConsumerSettings(
      kafkaConsumer,
      mqttClient,
      ConfigUtils.mqtt.mqttDirectivesTopicTemplate,
      ConfigUtils.mqtt.mqttUpgradeTopicTemplate,
      directiveTrackingEndpoints,
      systemModesEndpoints,
      x => serializer.serialize[Directive](x).replaceAll("\"stage", "\"stage_"),
      x => deserializer.deserialize[DirectiveMessage](x),
      Some(x => Directive.isValid(x.directive)),
      ConfigUtils.kafka.filterTimeInSeconds
    )
  )

  val supervisor = BackoffSupervisor.props(
    Backoff.onStop(
      directiveConsumerProps,
      childName = "directive-router-supervisor",
      minBackoff = 3.seconds,
      maxBackoff = 30.seconds,
      randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
    ).withSupervisorStrategy(
      OneForOneStrategy() {
        case ex =>
          system.log.error(ex, "There was an error in KafkaActor")
          SupervisorStrategy.Restart //Here we can add some log or send a notification
      })
  )

  system.actorOf(supervisor)

  val route =
    path("") {
      get {
        // TODO: Try to connect to real KAFKA
        // TODO: Try to authenticate with Twilio with real credentials (from env), but don't error if it's down
        complete(HttpEntity(contentType = ContentTypes.`text/html(UTF-8)`, "<h1>OK</h1>"))
      }
    }

  val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", 8000)
}