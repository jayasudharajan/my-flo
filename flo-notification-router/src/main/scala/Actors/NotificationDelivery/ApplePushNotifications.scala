package Actors.NotificationDelivery

import Models.Mediums.AppleMobileDeviceMessage
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, Props}
import akka.stream.ActorMaterializer
import argonaut.Argonaut._
import com.amazonaws.regions.{Region, Regions}
import com.amazonaws.services.sns.AmazonSNSClient
import com.amazonaws.services.sns.model._
import com.flo.Enums.Apps.{DeviceNotificationStatus, DevicePlatFormNames}
import com.flo.Enums.Notifications.{DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{AppDeviceNotificationInfoEnpoints, ICDAlarmIncidentRegistryLogEndpoints}
import com.flo.Models.AppDeviceNotificationInfo
import com.flo.Models.Logs.ICDAlarmIncidentRegistryLog
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._
import scala.util.{Failure, Success}

/**
  * Created by Francisco on 5/9/2016.
  */
class ApplePushNotifications extends Actor with ActorLogging {

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val DEFAULT_ARN = ApplicationSettings.flo.sns.apple.defaultArn.getOrElse(throw new Exception("flo.sns.apple.default-app-arn was not in application.conf or env vars"))

  private val AWS_SNS_CLIENT: AmazonSNSClient = new AmazonSNSClient()
  private lazy val FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO = new AppDeviceNotificationInfoEnpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)


  AWS_SNS_CLIENT.setRegion(
    if (Regions.getCurrentRegion == null)
      Region.getRegion(Regions.DEFAULT_REGION)
    else Region.getRegion(Regions.DEFAULT_REGION))

  override def preStart = {
    log.info(s"ApplePushNotifications started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"ApplePushNotifications stopped actor ${self.path.name} @ ${self.path.address}")

  }

  def receive = {

    case notification: AppleMobileDeviceMessage =>
      try {
        val logM = s"registry id: ${notification.icdAlarmIncidentRegistryId.getOrElse("NA")} icd id: ${notification.icdId}"

        if (notification.applePushNotification.isEmpty) {
          throw new IllegalArgumentException("applePushNotification needs to be defined")
        }
        if (notification.notificationTokens.isEmpty) {
          throw new IllegalArgumentException("notificationTokens needs to be defined")
        }
        val hasIosnotificationTokens = if (notification.notificationTokens.get.iosToken.isDefined && notification.notificationTokens.get.iosToken.get.nonEmpty) true else false
        if (!hasIosnotificationTokens) {
          log.error(s"user for icd_id: ${notification.icdId.get} has not notification tokens")
          throw new Exception("User has not iosNotificationTokens")
        }

        notification.notificationTokens.get.iosToken.get.foreach((token) => {
          var appDeviceNotificationInformation: Option[AppDeviceNotificationInfo] = notification.notificationInfo.get.find((i) => i.registrationToken.get == token)

          if (appDeviceNotificationInformation.isEmpty) {
            log.info(s"No appDeviceNotificationInfo found for $logM")
            appDeviceNotificationInformation = AppdeviceNotificationInfoGenerator(notification.notificationTokens.get.userId.get, notification.icdId.get, token)
          }

          if (appDeviceNotificationInformation.isDefined) {
            appDeviceNotificationInformation.get.status.getOrElse(DeviceNotificationStatus.OK) match {
              case DeviceNotificationStatus.OK =>
                val n = appDeviceNotificationInformation.get
                val notificationMessageJ = notification.applePushNotification.getOrElse(throw new IllegalArgumentException("Message cannot be empty")).asJson.toString()
                val icdAlarmIncidentRegistryId = notification.icdAlarmIncidentRegistryId

                try {
                  PublishNotification(n.endpointArn, n.userId, notificationMessageJ, icdAlarmIncidentRegistryId)
                }
                catch {
                  case e: Throwable =>

                    ExpulseDevice(n.endpointArn.get)
                    val nDeviceInfo = AppdeviceNotificationInfoGenerator(notification.notificationTokens.get.userId.get, notification.icdId.get, token).getOrElse(throw new Exception(s"unable to create appDeviceInfo record for userid : ${notification.notificationTokens.get.userId.get} notification token: $token"))

                    FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Put(Some(AppDeviceNotificationInfo(
                      id = n.id,
                      ts = n.ts,
                      tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                      icdId = n.icdId,
                      userId = n.userId,
                      platform = n.platform,
                      platformArn = n.platformArn,
                      endpointArn = n.endpointArn,
                      status = Some(DeviceNotificationStatus.ERROR),
                      statusMessage = Some(e.toString),
                      registrationToken = n.registrationToken,
                      isDeleted = Some(true)
                    ))).onComplete {
                      case Success(s) => log.info("updated AppDeviceNotificationInfo  to status error  ")
                      case Failure(f) => log.error(s"userID: ${n.userId.getOrElse("n/a")} token: ${n.registrationToken.getOrElse("N/A")}  ${f.toString}")
                    }
                    log.error(s"${e.toString} token:  ${n.registrationToken.getOrElse("n/a")} userId: ${n.userId.getOrElse("n/a")} ")
                    PublishNotification(nDeviceInfo.endpointArn, nDeviceInfo.userId, notificationMessageJ, icdAlarmIncidentRegistryId)

                  case error: Throwable =>
                    log.error(s"${error.toString} token:  ${n.registrationToken.getOrElse("n/a")} userId: ${n.userId.getOrElse("n/a")} ")
                }


              case DeviceNotificationStatus.UNSUBSCRIBE =>
                log.info(s"user is unsubscribed")

              case DeviceNotificationStatus.ERROR =>

                //If the status is error, give it another try, maybe the SNS problem has been fixed or app issue has been fixed

                val n = appDeviceNotificationInformation.get
                val notificationMessageJ = notification.applePushNotification.getOrElse(throw new IllegalArgumentException("Message cannot be empty")).asJson.toString()
                val icdAlarmIncidentRegistryId = notification.icdAlarmIncidentRegistryId
                try {

                  PublishNotification(n.endpointArn, n.userId, notificationMessageJ, icdAlarmIncidentRegistryId)

                  FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Put(Some(AppDeviceNotificationInfo(
                    id = n.id,
                    ts = n.ts,
                    tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                    icdId = n.icdId,
                    userId = n.userId,
                    platform = n.platform,
                    platformArn = n.platformArn,
                    endpointArn = n.endpointArn,
                    status = Some(DeviceNotificationStatus.OK),
                    statusMessage = None,
                    registrationToken = n.registrationToken,
                    isDeleted = Some(false)
                  ))).onComplete {
                    case Success(s) => log.info("Successfully updated AppDeviceNotificationInfo")
                    case Failure(f) => log.error(f.toString)
                  }
                }
                catch {
                  case error: Throwable =>
                    ExpulseDevice(n.endpointArn.get)
                    FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Put(Some(AppDeviceNotificationInfo(
                      id = n.id,
                      ts = n.ts,
                      tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                      icdId = n.icdId,
                      userId = n.userId,
                      platform = n.platform,
                      platformArn = n.platformArn,
                      endpointArn = n.endpointArn,
                      status = Some(DeviceNotificationStatus.ERROR),
                      statusMessage = Some(error.toString),
                      registrationToken = n.registrationToken,
                      isDeleted = Some(true)
                    ))).onComplete {
                      case Success(s) => log.info("Successfully updated AppDeviceNotificationInfo")
                      case Failure(f) => log.error(f.toString)
                    }
                    val ndInfo = AppdeviceNotificationInfoGenerator(notification.notificationTokens.get.userId.get, notification.icdId.get, token).getOrElse(throw new Exception(s"unable to create appDeviceInfo record for userid : ${notification.notificationTokens.get.userId.get} notification token: $token"))
                    log.error(s"Try to deliver notification to disable notification token, but it still failed  ${error.toString} token:  ${n.registrationToken.getOrElse("n/a")} userId: ${n.userId.getOrElse("n/a")} ")
                    PublishNotification(ndInfo.endpointArn, ndInfo.userId, notificationMessageJ, icdAlarmIncidentRegistryId)

                }


            }

          }
          else {
            log.warning("Unable to create AppNotificationInfo record")
          }
        })

        context.stop(self)
      }
      catch {
        case e: Throwable =>
          log.error(s"tokens: ${notification.notificationTokens.getOrElse("n/a").toString} ${e.toString}")
          context.stop(self)

      }

    case None =>
      log.warning("Empty message was sent....")
      context.stop(self)
  }

  /**
    * this function will create an arnEndpoint for a notification token, if all goes well it will record the endpoint arn in a appdeviceinfo object and dynamo, it will throw an exception otherwise.
    */
  ///TODO: Metric timer
  private def AppdeviceNotificationInfoGenerator(userId: String, icdId: String, iosNotificationToken: String): Option[AppDeviceNotificationInfo] = {
    if (userId.isEmpty || icdId.isEmpty || iosNotificationToken.isEmpty) {
      throw new IllegalArgumentException("Missing parameters")
    }
    val arnEndpoint: String = MatriculateDevice(iosNotificationToken).getOrElse(throw new Exception("was not able to matriculate token to arn"))
    val f = FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Post(
      Some(
        AppDeviceNotificationInfo(
          id = Some(java.util.UUID.randomUUID().toString),
          ts = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdId = Some(icdId),
          userId = Some(userId),
          platform = Some(DevicePlatFormNames.APPLE_IPHONE),
          platformArn = Some(DEFAULT_ARN),
          endpointArn = Some(arnEndpoint),
          status = Some(DeviceNotificationStatus.OK),
          statusMessage = None,
          registrationToken = Some(iosNotificationToken),
          isDeleted = Some(false)
        )
      )
    )
    Await.result(f, 10 seconds)
  }

  /**
    * using the user registration token it enrolls that particular user in AWS SNS it returns the ARNenpoint for that token, it returns an AWS exception otherwise.
    **/
  ///TODO: Metric timer
  private def MatriculateDevice(token: String): Option[String] = {
    val result = AWS_SNS_CLIENT.createPlatformEndpoint(
      new CreatePlatformEndpointRequest()
        .withPlatformApplicationArn(DEFAULT_ARN)
        .withToken(token)

    )
    log.info(s"endpoint registered ${result.toString}")
    Some(result.getEndpointArn)
  }

  /**
    * Deletes the especified ARN enpoint from AWS SNS
    **/
  ///TODO: Metric timer
  private def ExpulseDevice(endpointARN: String): Unit = {
    try {
      val result = AWS_SNS_CLIENT.deleteEndpoint(
        new DeleteEndpointRequest()
          .withEndpointArn(endpointARN)
      )
      log.info(s"deleted sns ARNendpoint: $endpointARN")
    }
    catch {
      case e: Throwable =>
        log.error(s"The following exception happened trying to delete endpoint ARN ${e.toString}")
    }
  }

  /**
    * Send push notification to amazon SNS to be sent to the mobile device via device  ARN endpoint
    **/
  ///TODO: Metric timer
  private def PublishNotification(aRNEndppoint: Option[String], userId: Option[String], pushNotificationJson: String, icdAlarmIncidentRegistryId: Option[String]): Unit = {
    try {
      val publishResult = AWS_SNS_CLIENT.publish(new PublishRequest()
        .withTargetArn(aRNEndppoint.get)
        .withMessage(pushNotificationJson)
        .withMessageStructure("json")
      )
      log.info(publishResult.toString)
      FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG.Post(Some(
        ICDAlarmIncidentRegistryLog(
          id = Some(java.util.UUID.randomUUID().toString),
          createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdAlarmIncidentRegistryId = icdAlarmIncidentRegistryId,
          userId = userId,
          deliveryMedium = Some(DeliveryMediums.PUSH_NOTIFICATION),
          status = Some(ICDAlarmIncidentRegistryLogStatus.SENT),
          receiptId = Some(publishResult.getMessageId)
        )

      )).onComplete {
        case Success(s) => log.info("ICDALARMINCIDENTREGISTRYLOG was created successfully push notification sent")
        case Failure(e) => log.error(e.toString)
      }
    }
    catch {
      case e: Throwable =>
        log.error(s"The following exception happened trying to send push notification for icdAlarmIncidentRegistryId : ${icdAlarmIncidentRegistryId.getOrElse("N/A")}  exception: ${e.toString} for push notification")
        throw e
    }
  }
}


object ApplePushNotifications {
  def props(): Props = Props(classOf[ApplePushNotifications])
}