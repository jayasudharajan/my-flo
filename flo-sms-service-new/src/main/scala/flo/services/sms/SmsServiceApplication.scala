package flo.services.sms

import akka.actor.{ActorSystem, OneForOneStrategy, SupervisorStrategy}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.SmsEndpoints
import com.flo.Models.KafkaMessages.SmsMessage
import com.flo.communication.KafkaConsumer
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}
import com.flo.utils.{FromSneakToCamelCaseDeserializer, HttpMetrics}
import com.typesafe.scalalogging.LazyLogging
import flo.services.sms.services.SmsKafkaConsumer
import flo.services.sms.utils.{ConfigUtils, TwilioClient}
import kamon.Kamon
import scala.concurrent.duration._

object SmsServiceApplication extends App with LazyLogging {

  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("sms-service-system")
  implicit val materializer = ActorMaterializer()
  implicit val executionContext = system.dispatcher

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
    clientName =  Some(ConfigUtils.kafka.consumerName),
    maxPollRecords = ConfigUtils.kafka.maxPollRecords,
    pollTimeout = ConfigUtils.kafka.pollTimeout
  )

  val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )
  val smsEndpoints = new SmsEndpoints(httpMetrics)

  val smsClient = new TwilioClient(ConfigUtils.twilio.accountSID, ConfigUtils.twilio.authToken, smsEndpoints)
  val deserializer = new FromSneakToCamelCaseDeserializer

  val smsConsumerProps = SmsKafkaConsumer.props(
    SmsKafkaConsumer.SmsConsumerSettings(
      kafkaConsumer,
      smsClient,
      x => deserializer.deserialize[SmsMessage](x),
      ConfigUtils.kafka.filterTimeInSeconds
    )
  )

  val supervisor = BackoffSupervisor.props(
    Backoff.onStop(
      smsConsumerProps,
      childName = "sms-consumer",
      minBackoff = 3.seconds,
      maxBackoff = 30.seconds,
      randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
    ).withSupervisorStrategy(
      OneForOneStrategy() {
        case ex =>
          system.log.error("There was an error in KafkaActor", ex)
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
