package Actors.NotificationDelivery

import MicroService.{SNSService, ValidationService}
import Models.Mediums.AndroidMobileDeviceMessage
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, Props}
import akka.stream.ActorMaterializer
import argonaut.Argonaut._
import com.flo.Enums.Apps.{DeviceNotificationStatus, DevicePlatFormNames}
import com.flo.FloApi.notifications.Delivery
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{AppDeviceNotificationInfoEnpoints, ICDAlarmIncidentRegistryLogEndpoints}
import com.flo.Models.AppDeviceNotificationInfo
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._
import scala.util.{Failure, Success}


/**
  * Created by Francisco on 2/24/2017.
  */
class AndroidPushNotifications extends Actor with ActorLogging {

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val DEFAULT_ARN = ApplicationSettings.flo.sns.android.defaultArn.getOrElse(throw new Exception("flo.sns.android.default-app-arn was not in application.conf or env vars"))

  private lazy val VALIDATION = new ValidationService()
  private lazy val SNS = new SNSService(DEFAULT_ARN)
  private val FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO = new AppDeviceNotificationInfoEnpoints(clientCredentialsTokenProvider)
  private val FLO_PROXY_ICD_ALARM_INCIDENT_REGESTRY_LOG = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)



  override def preStart = {
    log.info(s"AndroidPushNotifications started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"AndroidPushNotifications stopped actor ${self.path.name} @ ${self.path.address}")

  }

  def receive = {
    case notificationMsg: AndroidMobileDeviceMessage =>
      try {
        VALIDATION.validateAndroidMobileDeviceMessage(notificationMsg)
        lazy val userId = notificationMsg.notificationTokens.get.userId.get


        lazy val icdId = notificationMsg.icdId.get

        //if multiple notification tokens put them in a parallel array for faster processing
        notificationMsg.notificationTokens.get.androidToken.get.toParArray.foreach((token) => {
          var appDeviceNotificationInformation: Option[AppDeviceNotificationInfo] = notificationMsg.notificationInfo.get.find((i) => i.registrationToken.get == token)
          if (appDeviceNotificationInformation.isEmpty) {
            appDeviceNotificationInformation = appDeviceNotificationInfoGenerator(userId, icdId, token)
          }
          if (appDeviceNotificationInformation.isEmpty) {
            throw new Exception(s"unable to create appDevice info for userId: $userId icdId: $icdId notificationToken: $token")
          }

          appDeviceNotificationInformation.get.status.get match {
            case DeviceNotificationStatus.OK =>
              //For the sake of brevity
              val n = appDeviceNotificationInformation.get
              // create Json string for push notification
              val pnJson = notificationMsg.androidPushNotification.get.asJson.toString()
              try {
                SNS.publishPushNotification(n.endpointArn, pnJson)
              }
              catch {
                case e: com.amazonaws.services.sns.model.EndpointDisabledException =>
                  handleDisabledEndpointCase(n, e.toString, pnJson)
                case error: Throwable =>
                  log.error(s"${error.toString} token:  ${n.registrationToken.getOrElse("n/a")} userId: ${n.userId.getOrElse("n/a")} ")

              }
            case DeviceNotificationStatus.UNSUBSCRIBE =>
              log.info(s"user is unsubscribed")

            case DeviceNotificationStatus.ERROR =>
              //If the status is error, give it another try, maybe the SNS problem has been fixed or app issue has been fixed
              //For the sake of brevity
              val n = appDeviceNotificationInformation.get
              // create Json string for push notification
              val pnJson = notificationMsg.androidPushNotification.get.asJson.toString()
              try {
                SNS.publishPushNotification(n.endpointArn, pnJson)

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
                case e: Throwable =>
                  handleDisabledEndpointCase(n, e.toString, pnJson)
              }

          }

        })

        context.stop(self)
      }
      catch {
        case e: Throwable => log.error(e.toString)
          context.stop(self)
      }

  }

  /**
    * there are many factor that might render a endpoint to be disabled, this method will delete the push notification
    * endpoint that user, and it will try to re-enroll it again.
    **/
  private def handleDisabledEndpointCase(appDeviceInfo: AppDeviceNotificationInfo, ex: String, pnJson: String): Unit = {
    //delete arnEnpoint from ARN AWS SNS
    SNS.expulseDevice(appDeviceInfo.endpointArn.get)
    //Create   app Device info with new ARNEndpoint
    val adi = appDeviceNotificationInfoGenerator(appDeviceInfo.userId.get, appDeviceInfo.icdId.get, appDeviceInfo.registrationToken.get).getOrElse(
      throw new Exception(s"unable to create appDeviceInfo record for userId: ${appDeviceInfo.userId.get} androifNotificationToken: ${appDeviceInfo.registrationToken.get} icdId: ${appDeviceInfo.icdId.get}")
    )
    //Try to publish to new ARNEndpoint
    SNS.publishPushNotification(adi.endpointArn, pnJson)

    //update the old record and mark it as erred
    FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Put(Some(AppDeviceNotificationInfo(
      id = appDeviceInfo.id,
      ts = appDeviceInfo.ts,
      tsUpdated = appDeviceInfo.tsUpdated,
      icdId = appDeviceInfo.icdId,
      userId = appDeviceInfo.userId,
      platform = appDeviceInfo.platform,
      platformArn = appDeviceInfo.platformArn,
      endpointArn = appDeviceInfo.endpointArn,
      status = Some(DeviceNotificationStatus.ERROR),
      statusMessage = Some(ex),
      registrationToken = appDeviceInfo.registrationToken,
      isDeleted = Some(true)
    ))).onComplete {
      case Success(s) => log.info("updated AppDeviceNotificationInfo  to status error  ")
      case Failure(f) => log.error(s"handleDisabledEndpointCase ${f.toString}")
    }
    log.error(s"appDeviceNotificationInfoId: ${appDeviceInfo.id.get} error sending push notification to android: $ex")
  }

  /**
    * this function will create an arnEndpoint for a notification token, if all goes well it will record the endpoint
    * arn in a appdeviceinfo object and dynamo, it will throw an exception otherwise.
    */
  ///TODO: Metric timer
  private def appDeviceNotificationInfoGenerator(userId: String, icdId: String, androidNotificationToken: String): Option[AppDeviceNotificationInfo] = {
    if (userId.isEmpty || icdId.isEmpty || androidNotificationToken.isEmpty) {
      throw new IllegalArgumentException("Missing parameters")
    }
    val arnEndpoint: String = SNS.matriculateDevice(androidNotificationToken).getOrElse(throw new Exception("was not able to matriculate token to arn"))
    val f = FLO_PROXY_APP_NOTIFICATION_DEVICE_INFO.Post(
      Some(
        AppDeviceNotificationInfo(
          id = Some(java.util.UUID.randomUUID().toString),
          ts = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
          icdId = Some(icdId),
          userId = Some(userId),
          platform = Some(DevicePlatFormNames.ANDROID_PHONE),
          platformArn = Some(DEFAULT_ARN),
          endpointArn = Some(arnEndpoint),
          status = Some(DeviceNotificationStatus.OK),
          statusMessage = None,
          registrationToken = Some(androidNotificationToken),
          isDeleted = Some(false)
        )
      )
    )
    Await.result(f, 10 seconds)
  }

}

object AndroidPushNotifications {
  def props(): Props = Props(classOf[AndroidPushNotifications])
}





