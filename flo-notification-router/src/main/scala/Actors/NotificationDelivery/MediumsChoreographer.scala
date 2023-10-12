package Actors.NotificationDelivery

import Actors.KafkaProducer
import MicroService.{DecisionEngineService, SnapShotMicroService, TimeService}
import Models.Mediums._
import Models.ProducerMessages.{ProducerEmailMessage, ProducerSMSMessage}
import Nators.{ApplePushNotificationGenerators, ICDAlarmIncidentRegistryLogGenerator}
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, OneForOneStrategy, Props, SupervisorStrategy}
import akka.routing.RoundRobinPool
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.{DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.notifications.Delivery
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.ICDAlarmIncidentRegistryLogEndpoints
import com.flo.Models.KafkaMessages.{EmailMessage, SmsMessage}
import com.flo.Models._
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}


class MediumsChoreographer(producer: ActorRef) extends Actor with ActorLogging {

  implicit val mt = ActorMaterializer()(context)
  implicit val system = context.system
  implicit val ex = system.dispatcher

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )

  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  private lazy val proxyIncidentRegistryLog = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)

  //service
  private lazy val timeService = new TimeService()
  private lazy val snapshotService = new SnapShotMicroService()

  //nators
  private lazy val incidentRegistryLogNator = new ICDAlarmIncidentRegistryLogGenerator()

  //general
  private lazy val kafkaProducerWorkers = ApplicationSettings.floActors.numberOfWorkers.kafkaProducer.getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.kafka-producer was not found in config or environmental variables"))
  private val materializer = ActorMaterializer()(context)
  private lazy val API_URL = ApplicationSettings.flo.api.url.getOrElse(throw new Exception("FLO_API_URL was not found in config nor env vars"))

  val delivery = new Delivery()

  override def preStart = {
    log.info(s"MediumsChoreographer started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"MediumsChoreographer stopped actor ${self.path.name} @ ${self.path.address}")

  }

  override def supervisorStrategy = OneForOneStrategy() {
    case (ex: Throwable) => log.error(ex, "")
      SupervisorStrategy.Stop
  }

  def receive = {

    case floice: FloiceActorMessage => delivery
      .getDeliverySystemVersionForUser(floice.userContactInformation.userId.getOrElse(""))
      .map { x =>
        if (x.version == 1) {
          val floiceActor = context.actorOf(Floice.props(producer, floice.unitSystem))

          floiceActor ! floice
        }
      }

    case pnMsg: PushNotificationChoreographerMessage => if(ApplicationSettings.push.enabled) {
      delivery
        .getDeliverySystemVersionForUser(pnMsg.userInfo.map(_.userId.getOrElse("")).getOrElse(""))
        .map { x =>
          if (x.version == 1) {
            //apple
            applePNFlow(pnMsg)

            //android
            androidPushNotificationFlow(pnMsg)
            //Record progress
            proxyIncidentRegistryLog.Post(Some(incidentRegistryLogNator.registryLogPost(pnMsg.createIcdIncidentRegistryRecord.get.id, pnMsg.userInfo.get.userId.get, DeliveryMediums.PUSH_NOTIFICATION, ICDAlarmIncidentRegistryLogStatus.TRIGGERED, None)))
          }
        }
    }

    case smsMsg: SMSChoreographerMessage => delivery
      .getDeliverySystemVersionForUser(smsMsg.userInfo.map(_.userId.getOrElse("")).getOrElse(""))
      .map { x =>
        if (x.version == 1) {
          val producer = context.system.actorOf(RoundRobinPool(kafkaProducerWorkers).props(KafkaProducer.props(materializer)))
          producer ! smsProducerMessageGenerator(smsMsg)
        }
      }

    case emailMsg: EmailChoreographerMessage => delivery
      .getDeliverySystemVersionForUser(emailMsg.userInfo.map(_.userId.getOrElse("")).getOrElse(""))
      .map { x =>
        if (x.version == 1) {
          val producer = context.system.actorOf(RoundRobinPool(kafkaProducerWorkers).props(KafkaProducer.props(materializer)))
          producer ! emailProducerMessageGenerator(emailMsg)
        }
      }
  }

  private def emailProducerMessageGenerator(eMsg: EmailChoreographerMessage): ProducerEmailMessage = {
    val snapshot = eMsg.icdAlarmIncidentMessage.data.snapshot
    lazy val decisionEngineService = new DecisionEngineService(eMsg.unitSystem)


    ProducerEmailMessage(
      EmailMessage(
        id = Some(java.util.UUID.randomUUID().toString),
        ts = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
        notificationTime = Some(timeService.epochTimeStampToStringISODate(Some(eMsg.icdAlarmIncidentMessage.ts))),
        notification = Some(eMsg.icdAlarmNotificationDeliveryRules),
        icd = Some(ICD(
          eMsg.iCd.get.deviceId,
          timeZone = snapshot.timeZone,
          systemMode = snapshot.systemMode,
          localTime = snapshot.localTime,
          id = eMsg.iCd.get.id,
          locationId = eMsg.iCd.get.locationId
        )),
        telemetry = snapshotService.snapshotToTelemetryGenerator(snapshot.unitSystemConversion(eMsg.unitSystem)),
        userContactInformation = eMsg.userInfo,
        location = eMsg.icdLocation,
        statusCallback = decisionEngineService.EmailStatusCallbackGenerator(API_URL, Some(eMsg.createIcdIncidentRegistryRecord.id), eMsg.userInfo.get.userId.get),
        Some(eMsg.createIcdIncidentRegistryRecord.friendlyDescription),
        measurementUnitSystem = Some(eMsg.unitSystem)
      ),
      icdAlarmIncidentRegistryId = eMsg.createIcdIncidentRegistryRecord.id
    )
  }

  private def smsProducerMessageGenerator(smsMsg: SMSChoreographerMessage): ProducerSMSMessage = {
    lazy val decisionEngineService = new DecisionEngineService(smsMsg.unitSystem)

    ProducerSMSMessage(
      sMSMessage = SmsMessage(
        id = java.util.UUID.randomUUID().toString,
        text = decisionEngineService.SMSTextnator1505000(smsMsg.icdAlarmNotificationDeliveryRules, smsMsg.icdAlarmIncidentMessage.postAutoResolutionInfo).getOrElse(throw new Exception("Could not build text for SMS")),
        phone = smsMsg.userInfo.get.phoneMobile.getOrElse(throw new Exception("user does not have a mobile phone number in record")),
        deliveryCallback = "",
        postDeliveryCallback = ""

      ),
      icdAlarmIncidentRegistryId = smsMsg.createIcdIncidentRegistryRecord.id,
      userId = smsMsg.userInfo.get.userId.get
    )
  }

  private def applePNFlow(pnMsg: PushNotificationChoreographerMessage): Unit = {
    if (pnMsg.notificationTokens.get.iosToken.isDefined && pnMsg.notificationTokens.get.iosToken.get.nonEmpty) {
      lazy val applePNNator = new ApplePushNotificationGenerators(pnMsg.unitSystem)
      val ipusher = context.actorOf(Props[ApplePushNotifications])
      ipusher ! applePNNator.appleMobileDeviceMessageFromChoreographerMessage(pnMsg)
    }
    else {
      log.info(s"user:${pnMsg.notificationTokens.get.userId.getOrElse("n/a")}  has not IOS notification tokens")
    }

  }

  private def androidPushNotificationFlow(pnMsg: PushNotificationChoreographerMessage): Unit = {
    lazy val decisionEngineService = new DecisionEngineService(pnMsg.unitSystem)


    if (pnMsg.notificationTokens.get.androidToken.isDefined && pnMsg.notificationTokens.get.androidToken.nonEmpty) {
      val androidPushNotificationPusher = context.actorOf(Props[AndroidPushNotifications])

      androidPushNotificationPusher ! AndroidMobileDeviceMessage(
        notificationInfo = decisionEngineService.AppDeviceInfoGetNonDeleted(Some(pnMsg.appDeviceInfo.get)),
        androidPushNotification = decisionEngineService.androidPushNotificationObjectGenerator(pnMsg.icdAlarmNotificationDeliveryRules,
          icdAlarmIncidentRegistry = pnMsg.createIcdIncidentRegistryRecord.get,
          icd = ICD(
            deviceId = Some(pnMsg.icdAlarmIncidentMessage.deviceId),
            timeZone = pnMsg.icdAlarmIncidentMessage.data.snapshot.timeZone,
            systemMode = pnMsg.icdAlarmIncidentMessage.data.snapshot.systemMode,
            localTime = pnMsg.icdAlarmIncidentMessage.data.snapshot.localTime,
            id = pnMsg.iCD.get.id,
            locationId = pnMsg.iCD.get.locationId
          ),
          location = pnMsg.location.get,
          postAutoResolutionInfo = pnMsg.icdAlarmIncidentMessage.postAutoResolutionInfo
        ),
        notificationTokens = Some(pnMsg.notificationTokens.get),
        icdId = pnMsg.iCD.get.id,
        icdAlarmIncidentRegistryId = Some(pnMsg.createIcdIncidentRegistryRecord.get.id)
      )
    }
    else {
      log.info(s"user:${pnMsg.userInfo.get.userId.getOrElse("n/a")}  has not Android notification tokens")
    }

  }


}

object MediumsChoreographer {
  def props(producer: ActorRef): Props = Props(classOf[MediumsChoreographer], producer)
}
