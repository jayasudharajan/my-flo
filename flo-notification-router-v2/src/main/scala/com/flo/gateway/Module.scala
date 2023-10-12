package com.flo.gateway

import java.time.{Instant, LocalDateTime, ZoneOffset}

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity, HttpMethods, HttpRequest, HttpResponse}
import akka.http.scaladsl.unmarshalling.Unmarshaller
import akka.pattern.RetrySupport
import akka.stream.ActorMaterializer
import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.FloApi.gateway.api.{Account, HealthTestResult, SystemMode}
import com.flo.FloApi.gateway.{Accounts, Devices, Users}
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsGrantInfo, FloTokenProviders, OAuth2AuthProvider}
import com.flo.FloApi.v2.UserAccountGroupRoleEndpoints
import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.Models.Users.UserAccountGroupRole
import com.flo.logging.logbookFor
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api.{
  AlarmSystemModeDeliverySettings,
  AutoHealthTest,
  Device,
  DeviceId,
  DeviceUsers,
  Enterprise,
  HealthTest,
  HealthTestByDeviceIdRetriever,
  HealthTestId,
  Imperial,
  LatestHealthTestByDeviceIdRetriever,
  Location,
  ManualHealthTest,
  Metric,
  Personal,
  User,
  UserDevice,
  UserId,
  UserLocation,
  UsersByMacAddressRetriever,
  Account => RouterAccount
}
import com.flo.utils.{HttpMetrics, IHttpMetrics}
import com.github.blemale.scaffeine.{Cache, Scaffeine}
import com.typesafe.config.Config
import kamon.Kamon
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

trait Module {
  import Module.log

  // Requires
  implicit def defaultExecutionContext: ExecutionContext
  def appConfig: Config
  def actorSystem: ActorSystem
  def actorMaterializer: ActorMaterializer
  def serializeEmail: EmailFeatherMessage => String

  // Privates
  implicit private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-public-gateway",
    tags = Map("service-name" -> "flo-notification-router-v2")
  )
  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(actorSystem, actorMaterializer, httpMetrics)

  private val authProvider = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)

  private val devicesClient = {
    new Devices()(authProvider)(actorSystem, actorMaterializer, httpMetrics)
  }
  private val usersClient = {
    new Users()(authProvider)(actorSystem, actorMaterializer, httpMetrics)
  }
  private val accountsClient = {
    new Accounts()(authProvider)(actorSystem, actorMaterializer, httpMetrics)
  }
  private val userAccountGroupRolesClient = {
    new UserAccountGroupRoleEndpoints(authProvider)(actorSystem, actorMaterializer, httpMetrics)
  }

  private val usersCacheByMacAddress: Cache[String, DeviceUsers] =
    Scaffeine()
      .recordStats()
      .expireAfterWrite(5.minutes)
      .maximumSize(5000)
      .build[String, DeviceUsers]()

  private val landLordsRoles = Set(UserGroupAccountRoles.LANDLORD, UserGroupAccountRoles.PROPERTY_MANAGER)

  private def isPropertyManaged(roles: Seq[UserAccountGroupRole]): Boolean =
    roles.exists(_.roles.contains(UserGroupAccountRoles.LANDLORD))

  private def getLandlordUserIds(roles: Seq[UserAccountGroupRole]): Seq[String] =
    roles
      .withFilter(_.roles.exists(landLordsRoles.contains))
      .map(_.userId)

  private def getUserAccountGroupRolesByAccount(maybeAccount: Option[Account]): Future[Seq[UserAccountGroupRole]] = {
    val groups = maybeAccount.map(_.groups).getOrElse(Nil)

    val groupRoles = Future
      .traverse(groups) { group =>
        userAccountGroupRolesClient
          .Get(group.id)
          .map(mayBeGroupInfo => mayBeGroupInfo.getOrElse(Nil))
      }
      .map(_.flatten)

    groupRoles
  }

  private def getUser(userId: String, roles: Seq[String], maybeAccount: Option[Account]): Future[Option[User]] = {
    val accountType = maybeAccount.flatMap(_.`type`) match {
      case Some("enterprise") => Enterprise
      case _                  => Personal
    }
    val expand = accountType match {
      case Personal => Seq("locations")
      case _        => Seq()
    }
    usersClient
      .get(userId, expand)
      .map {
        _.map { user =>
          val account = RouterAccount(user.account.id, accountType)
          User(
            user.id,
            user.firstName,
            user.lastName.getOrElse(""),
            user.email,
            user.phoneMobile,
            user.unitSystem.map {
              case "imperial_us" => Imperial
              case "metric_kpa"  => Metric
            },
            if (user.locale.isEmpty) "en-us" else user.locale.toLowerCase,
            account,
            None,
            roles,
            user.locations.map { l =>
              UserLocation(l.id, l.expanded.map(_.devices.map(d => UserDevice(d.id))).getOrElse(Seq()))
            }
          )
        }
      }
  }

  private def toHealthTest(healthTestResult: Option[HealthTestResult]): Option[HealthTest] =
    healthTestResult.map { healthTest =>
      val healthTestType = {
        if (healthTest.`type` == "auto") AutoHealthTest
        else ManualHealthTest
      }
      HealthTest(
        healthTest.roundId,
        healthTest.deviceId,
        healthTestType,
        LocalDateTime.ofInstant(Instant.ofEpochMilli(healthTest.created.getMillis), ZoneOffset.UTC)
      )
    }

  // Provides
  val retrieveLatestHealthTestResultByDeviceId: LatestHealthTestByDeviceIdRetriever = (deviceId: String) =>
    devicesClient.getHealthTest(deviceId, "latest").map(toHealthTest)

  val retrieveHealthTestResultByDeviceId: HealthTestByDeviceIdRetriever =
    (deviceId: String, healthTestId: HealthTestId) => {
      devicesClient.getHealthTest(deviceId, healthTestId).map(toHealthTest)
    }

  val retrieveUsersByMacAddress: UsersByMacAddressRetriever = (macAddress: String) => {
    usersCacheByMacAddress.getIfPresent(macAddress) match {
      case Some(users) => Future.successful(Some(users))
      case None =>
        devicesClient
          .getByMacAddress(macAddress, Seq("location"))
          .flatMap {
            case None => Future.successful(None)

            case Some(device) if device.location.expanded.isEmpty =>
              log.error(p"Device Location should not be empty. DeviceId=${device.id}, LocationId=${device.location.id}")
              Future.successful(None)

            case Some(device) =>
              val location                      = device.location.expanded.get
              val accountId                     = device.location.expanded.get.account.id
              val userIds                       = location.users.map(_.id)
              val eventualAccount               = accountsClient.get(accountId, Seq())
              val eventualUserAccountGroupRoles = eventualAccount.flatMap(getUserAccountGroupRolesByAccount)
              val eventualGroupId               = eventualUserAccountGroupRoles.map(role => role.headOption.map(_.groupId))
              val eventualIsPropertyManaged     = eventualUserAccountGroupRoles.map(isPropertyManaged)

              val eventualRegularUsers = eventualIsPropertyManaged.flatMap(
                isPropertyManaged =>
                  Future.traverse(userIds) { userId =>
                    val roles = if (isPropertyManaged) Seq(UserGroupAccountRoles.TENANT) else Nil
                    eventualAccount.flatMap(maybeAccount => getUser(userId, roles, maybeAccount))
                }
              )

              val eventualLandlordUsers = eventualUserAccountGroupRoles.flatMap { roles =>
                Future.traverse(getLandlordUserIds(roles)) { userId =>
                  val userRoles = roles.withFilter(_.userId == userId).flatMap(_.roles)
                  eventualAccount.flatMap(maybeAccount => getUser(userId, userRoles, maybeAccount))
                }
              }

              for {
                regularUsers  <- eventualRegularUsers
                landlordUsers <- eventualLandlordUsers
                maybeGroupId  <- eventualGroupId
              } yield {
                val allUsers = (regularUsers ++ landlordUsers)
                  .flatMap(maybeUser => maybeUser.map(_.copy(groupId = maybeGroupId)))
                val deviceUsers = DeviceUsers(
                  Device(
                    device.id,
                    device.macAddress,
                    Location(
                      location.id,
                      location.address,
                      location.address2,
                      location.city,
                      location.state,
                      location.country,
                      location.postalCode,
                      location.timezone,
                      location.nickname
                    ),
                    device.floSense.map(x => x.shutoffLevel),
                    device.nickname
                  ),
                  allUsers
                )

                usersCacheByMacAddress.put(macAddress, deviceUsers)

                Some(deviceUsers)
              }
          }
    }
  }

  val retrieveHierarchyAwareDeliverySettings: (UserId, DeviceId) => Future[Seq[AlarmSystemModeDeliverySettings]] =
    (userId, deviceId) =>
      usersClient.retrieveAlarmSettingsByDevice(userId, List(deviceId)).map { deviceAlarmSettingsList =>
        deviceAlarmSettingsList.items.headOption
          .fold(Seq[AlarmSystemModeDeliverySettings]()) { deviceAlarmSettings =>
            deviceAlarmSettings.settings.map { s =>
              AlarmSystemModeDeliverySettings(
                s.alarmId,
                SystemMode.asInt(s.systemMode),
                s.smsEnabled.getOrElse(false),
                s.emailEnabled.getOrElse(false),
                s.pushEnabled.getOrElse(false),
                s.callEnabled.getOrElse(false),
                s.isMuted.getOrElse(false)
              )
            }
          }
    }

  private val emailGatewayUrl         = appConfig.as[String]("email.email-gateway-url")
  private val emailGatewayQueuePath   = appConfig.as[String]("email.email-gateway-url-queue-path")
  private val emailGatewayQueueMethod = appConfig.as[String]("email.email-gateway-url-queue-method")
  val sendToEmailGateway: EmailFeatherMessage => Future[HttpResponse] = (email: EmailFeatherMessage) => {
    val entity = serializeEmail(email)
    val httpRequest = HttpRequest(
      method = HttpMethods.getForKeyCaseInsensitive(emailGatewayQueueMethod).getOrElse(HttpMethods.POST),
      uri = p"$emailGatewayUrl$emailGatewayQueuePath",
      entity = HttpEntity(ContentTypes.`application/json`, entity)
    )

    log.debug(p"Sending ${httpRequest.method} ${httpRequest.uri.toString()}")
    RetrySupport.retry[HttpResponse](
      attempt = () => {
        Http()(actorSystem)
          .singleRequest(httpRequest)
          .map {
            case r if r.status.isSuccess() => r
            case r =>
              throw new Exception(
                p"Error sending email - status: ${r.status.value} - body: ${Unmarshaller.stringUnmarshaller(r.entity)(defaultExecutionContext, actorMaterializer)}"
              )
          }
      },
      attempts = 3,
      delay = 5.seconds
    )(defaultExecutionContext, actorSystem.scheduler)
  }
}

object Module {
  private val log = logbookFor(getClass)
}
