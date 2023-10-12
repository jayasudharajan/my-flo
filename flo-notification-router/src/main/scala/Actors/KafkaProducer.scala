package Actors

import Models.ProducerMessages.{ProducerEmailMessage, ProducerSMSMessage, ProducerVoiceMessage}
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, Props}
import akka.kafka.scaladsl._
import akka.kafka.{ProducerMessage, ProducerSettings}
import akka.stream.scaladsl.Source
import akka.stream.{ActorMaterializer, Materializer}
import argonaut.Argonaut._
import com.flo.Enums.Notifications.{DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.ICDAlarmIncidentRegistryLogEndpoints
import com.flo.Models.KafkaMessages.{EmailFeatherMessage, Task}
import com.flo.Models.Logs.ICDAlarmIncidentRegistryLog
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}
import com.flo.utils.{FromCamelToSneakCaseSerializer, HttpMetrics}
import kamon.Kamon
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.{ByteArraySerializer, StringSerializer}
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

/**
  * Created by Francisco on 5/19/2016.
  */
class KafkaProducer(mat: Materializer) extends Actor with ActorLogging {
  implicit val mt = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  implicit val materializer: Materializer = mat

  val FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)

  val cipher = new FLOCipher
  val keyProvider = new S3RSAKeyProvider(
    ApplicationSettings.cipher.keyProvider.bucketRegion,
    ApplicationSettings.cipher.keyProvider.bucketName,
    ApplicationSettings.cipher.keyProvider.keyPathTemplate
  )
  val rotationStrategy = new KeyIdRotationStrategy
  val encryptionPipeline = new EncryptionPipeline(cipher, keyProvider, rotationStrategy)

  def receive = {

    case producerEmailMessage: ProducerEmailMessage =>
      try {
        val emailMessage = producerEmailMessage.emailMessage

        val kafkaMessage = if (ApplicationSettings.kafka.encryption) {
          encryptionPipeline.encrypt(ApplicationSettings.cipher.keyProvider.keyId, emailMessage.asJson.nospaces)
        } else {
          emailMessage.asJson.nospaces
        }

        //settings
        val producerSettings = ProducerSettings(system, new ByteArraySerializer, new StringSerializer)
          .withBootstrapServers(
            if (ApplicationSettings.kafka.host.isDefined)
              ApplicationSettings.kafka.host.get
            else throw new IllegalArgumentException("a value for kafka-email-producer-host was not found in environment nor config")
          )

        Source.single(emailMessage)
          .map(
            m =>
              ProducerMessage.Message(new ProducerRecord[Array[Byte], String](
                ApplicationSettings.kafka.emailProducerTopic.getOrElse(throw new IllegalArgumentException("a value for kafka-email-producer-topic was not found in configuration nor system environment")),
                kafkaMessage
              ),
                emailMessage)
          )
          .via(Producer.flow(producerSettings))
          .map { result =>
            val record = result.message.record
            s"${record.topic}/${record.partition} ${result.offset}"
          }.runForeach(record => log.info(record)).map(done => {
          if (!producerEmailMessage.isCsEmail) {
            FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG.Post(Some(
              ICDAlarmIncidentRegistryLog(
                id = Some(java.util.UUID.randomUUID().toString),
                createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                icdAlarmIncidentRegistryId = Some(producerEmailMessage.icdAlarmIncidentRegistryId),
                userId = emailMessage.userContactInformation.getOrElse(throw new Exception("UserContactInformation missing from emailMesage ")).userId,
                deliveryMedium = Some(DeliveryMediums.EMAIL),
                status = Some(ICDAlarmIncidentRegistryLogStatus.TRIGGERED),
                receiptId = Some(java.util.UUID.randomUUID().toString)
              )

            )).onComplete {
              case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully")
              case Failure(e) => log.error(e.toString)
            }
          }
          else {
            log.info(s"incident_id: ${producerEmailMessage.icdAlarmIncidentRegistryId} successfully queued for delivery for CS")
          }


        })


      }
      catch {
        case e: Throwable =>
          log.error(e.toString)
      }

    //######################################SMS#######################################################

    case produceSmsMessage: ProducerSMSMessage =>
      try {
        val smsMessage = produceSmsMessage.sMSMessage

        val kafkaMessage = if (ApplicationSettings.kafka.encryption) {
          encryptionPipeline.encrypt(ApplicationSettings.cipher.keyProvider.keyId, smsMessage.asJson.nospaces)
        } else {
          smsMessage.asJson.nospaces
        }

        //settings
        val producerSettings = ProducerSettings(system, new ByteArraySerializer, new StringSerializer)
          .withBootstrapServers(
            if (ApplicationSettings.kafka.host.isDefined)
              ApplicationSettings.kafka.host.get
            else throw new IllegalArgumentException("a value for kafka-sms-producer-host was not found in environment nor config")
          )

        Source.single(smsMessage)
          .map(m =>
            ProducerMessage.Message(new ProducerRecord[Array[Byte], String](
              ApplicationSettings.kafka.smsProducerTopic.getOrElse(throw new IllegalArgumentException("a value for kafka-sms-producer-topic was not found in configuration nor system environment")),
              kafkaMessage
            ),
              smsMessage)
          )
          .via(Producer.flow(producerSettings))
          .map { result =>
            val record = result.message.record
            s"${record.topic}/${record.partition} ${result.offset}: (${result.message.passThrough}"


          }.runForeach(record => log.info(record)).map(done => {
          FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG.Post(Some(
            ICDAlarmIncidentRegistryLog(
              id = Some(java.util.UUID.randomUUID().toString),
              createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
              icdAlarmIncidentRegistryId = Some(produceSmsMessage.icdAlarmIncidentRegistryId),
              userId = Some(produceSmsMessage.userId),
              deliveryMedium = Some(DeliveryMediums.SMS),
              status = Some(ICDAlarmIncidentRegistryLogStatus.TRIGGERED),
              receiptId = Some(java.util.UUID.randomUUID().toString)
            )

          )).onComplete {
            case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully")
            case Failure(e) => log.error(e.toString)
          }


        })


      }
      catch {
        case e: Throwable =>
          log.error(e.toString)
      }

    case scheduledTask: Task =>

      val serializer = new FromCamelToSneakCaseSerializer()
      val taskSerializer = (task: Task) => serializer.serialize[Task](task)
      val kafkaMessage = if (ApplicationSettings.kafka.encryption) {
        encryptionPipeline.encrypt(ApplicationSettings.cipher.keyProvider.keyId, taskSerializer.apply(scheduledTask))
      } else {
        taskSerializer.apply(scheduledTask)
      }


      //settings
      val producerSettings = ProducerSettings(system, new ByteArraySerializer, new StringSerializer)
        .withBootstrapServers(
          if (ApplicationSettings.kafka.host.isDefined)
            ApplicationSettings.kafka.host.get
          else throw new IllegalArgumentException("a value for kafka-sms-producer-host was not found in environment nor config")
        )
      Source.single(scheduledTask).map(
        m =>
          ProducerMessage.Message(new ProducerRecord[Array[Byte], String](
            ApplicationSettings.kafka.scheduledNotificationsTaskTopic.getOrElse(throw new IllegalArgumentException("a value for kafka-scheduled-notifications.scheduled-task.topic was not found in configuration nor system environment")),
            kafkaMessage
          ),
            scheduledTask)

      ).via(Producer.flow(producerSettings))
        .map { result =>
          val record = result.message.record
          s"${record.topic}/${record.partition} ${result.offset}: (${result.message.passThrough}"
        }.runForeach(record => log.info(record)).map(
        done =>
          log.info("Notification was scheduled ")

      )

    case emailFeather: EmailFeatherMessage =>
      val kafkaMsg = if (ApplicationSettings.kafka.encryption) {
        encryptionPipeline.encrypt(ApplicationSettings.cipher.keyProvider.keyId, emailFeather.asJson.nospaces)
      }
      else {
        emailFeather.asJson.nospaces
      }
      //settings
      val producerSettings = ProducerSettings(system, new ByteArraySerializer, new StringSerializer)
        .withBootstrapServers(
          if (ApplicationSettings.kafka.host.isDefined)
            ApplicationSettings.kafka.host.get
          else throw new IllegalArgumentException("a value for kafka-sms-producer-host was not found in environment nor config")
        )
      Source.single(emailFeather).map(
        message =>
          ProducerMessage.Message(new ProducerRecord[Array[Byte], String](
            ApplicationSettings.kafka.emailProducerTopicV2.getOrElse(throw new IllegalArgumentException("a value for kafka.email-producer-topic-v2 was not found in configuration nor environmental variables")),
            kafkaMsg
          ), emailFeather
          )
      ).via(Producer.flow(producerSettings)).map {
        result =>
          val record = result.message.record
          s"${record.topic}/${record.partition} ${result.offset}"
      }.runForeach(record => log.info(record)).map(
        done =>
          log.info("Email was queued")
      )

    case floiceProducerMsg: ProducerVoiceMessage =>
      val voice = floiceProducerMsg.floiceMessage
      val kafkaMsg = voice.asJson.nospaces
      val producerSettings = ProducerSettings(system, new ByteArraySerializer, new StringSerializer).withBootstrapServers(
        if (ApplicationSettings.kafka.host.isDefined)
          ApplicationSettings.kafka.host.get
        else throw new IllegalArgumentException("a value for kafka-sms-producer-host was not found in environment nor config")
      )
      Source.single(voice).map(
        message =>
          ProducerMessage.Message(new ProducerRecord[Array[Byte], String](
            ApplicationSettings.kafka.voiceTopic.getOrElse(throw new IllegalArgumentException("kafka topic for voice was not found")),
            kafkaMsg
          ), voice)
      ).via(Producer.flow(producerSettings)).map {
        result =>
          val record = result.message.record
          s"${record.topic}/${record.partition} ${result.offset}"
      }.runForeach(record => log.info(record)).map(
        done => {
          FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG.Post(
            Some(ICDAlarmIncidentRegistryLog(
              id = Some(java.util.UUID.randomUUID().toString),
              createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
              icdAlarmIncidentRegistryId = Some(floiceProducerMsg.incidentId),
              userId = Some(floiceProducerMsg.userId),
              deliveryMedium = Some(DeliveryMediums.VOICE),
              status = Some(ICDAlarmIncidentRegistryLogStatus.TRIGGERED),
              receiptId = Some(java.util.UUID.randomUUID().toString)

            ))
          ).onComplete {
            case Success(s) => log.info(s"ICDALARMINCIDENTREGISTRYLOG was created successfully for incident ${floiceProducerMsg.incidentId}")
            case Failure(e) => log.error(s"${e.toString} for incident ${floiceProducerMsg.incidentId}")
          }
        }
      )

    case _ => // Message sent does not match a medium

      log.error("Message sent was not properly formatted")
  }


}

object KafkaProducer {
  def props(mat: Materializer): Props = Props(classOf[KafkaProducer], mat)
}