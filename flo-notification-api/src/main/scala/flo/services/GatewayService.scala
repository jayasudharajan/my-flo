package flo.services

import java.util.UUID

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.gateway.api.{
  ChangeSystemModeRequest,
  FirmwareProperties,
  MutableDevice,
  ValveState,
  Device => ApiDevice,
  User => ApiUser
}
import com.flo.FloApi.gateway.{Devices, Users}
import com.flo.FloApi.v2.Abstracts.{
  ClientCredentialsGrantInfo,
  FloTokenProviders,
  GenericAuthorizationProvider,
  OAuth2AuthProvider
}
import com.flo.notification.sdk.model.SystemMode
import com.flo.utils.{HttpMetrics, IHttpMetrics}
import com.github.blemale.scaffeine.{Cache, Scaffeine}
import com.google.inject.assistedinject.Assisted
import flo.util.TypeConversionImplicits._
import javax.inject.Inject
import kamon.Kamon

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

trait GatewayServiceFactory {
  def create(accessToken: String): GatewayService
}

trait GatewayService {
  def getUserWithLocations(userId: UUID): Future[Option[User]]
  def getUserUnsafe(userId: UUID): Future[Option[User]]
  def closeValve(deviceId: UUID): Future[Unit]
  def setToSleep(deviceId: UUID, sleepMinutes: Int): Future[Unit]
  def getDevice(deviceId: UUID): Future[Option[ApiDevice]]
  def setFwProperties(deviceId: UUID, fwProperties: FirmwareProperties): Future[Unit]
}

class DefaultGatewayService @Inject()(@Assisted accessToken: String)(implicit ec: ExecutionContext,
                                                                     actorSystem: ActorSystem,
                                                                     actorMaterializer: ActorMaterializer)
    extends GatewayService {

  private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-public-gateway",
    tags = Map("service-name" -> "flo-notification-api-v2")
  )

  private val userCache: Cache[UUID, User] =
    Scaffeine()
      .recordStats()
      .expireAfterWrite(5.minutes)
      .maximumSize(2000)
      .build[UUID, User]()

  private val authProviderWithAccessToken = new GenericAuthorizationProvider(accessToken)

  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(actorSystem, actorMaterializer, httpMetrics)
  private val authProviderWithClientCredentials = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)

  private val user = new Users()(authProviderWithAccessToken)(actorSystem, actorMaterializer, httpMetrics)
  private val usersWithClientCredentials =
    new Users()(authProviderWithClientCredentials)(actorSystem, actorMaterializer, httpMetrics)
  private val devicesWithClientCredentials =
    new Devices()(authProviderWithClientCredentials)(actorSystem, actorMaterializer, httpMetrics)

  override def getUserUnsafe(userId: UUID): Future[Option[User]] =
    userCache.getIfPresent(userId) match {
      case None =>
        usersWithClientCredentials.get(userId.toString, Seq()).map { maybeUser =>
          maybeUser.map { user =>
            val u = fromApiUser(user)
            userCache.put(userId, u)
            u
          }
        }
      case user => Future.successful(user)
    }

  override def getUserWithLocations(userId: UUID): Future[Option[User]] = {
    val userInfo = user.get(userId.toString, Seq("locations"))
    userInfo.map { maybeUser =>
      maybeUser.map { user =>
        fromApiUser(user)
      }
    }
  }

  private def fromApiUser(apiUser: ApiUser): User = {
    val locations = apiUser.locations.map { l =>
      Location(l.id, l.expanded.map(_.devices.map(d => Device(d.id))).getOrElse(Seq()))
    }

    val userLocale = if (apiUser.locale.isEmpty) "en-us" else apiUser.locale.toLowerCase

    User(
      apiUser.id,
      apiUser.account.id,
      locations,
      userLocale
    )
  }

  override def closeValve(deviceId: UUID): Future[Unit] =
    devicesWithClientCredentials.get(deviceId.toString, Seq()).flatMap {
      case None => Future.unit

      case Some(d) =>
        val mutableDevice = MutableDevice(
          d.installationPoint,
          d.prvInstallation,
          d.irrigationType,
          Some(ValveState("closed")),
          d.nickname
        )
        devicesWithClientCredentials.updateDevice(deviceId.toString, mutableDevice).map(_ => ())

    }

  override def setToSleep(deviceId: UUID, sleepMinutes: Int): Future[Unit] =
    devicesWithClientCredentials.get(deviceId.toString, Seq()).flatMap {
      case None => Future.unit

      case Some(_) =>
        devicesWithClientCredentials
          .setSystemMode(
            deviceId.toString,
            ChangeSystemModeRequest(
              SystemMode.toString(SystemMode.Sleep),
              Some(SystemMode.toString(SystemMode.Home)),
              Some(sleepMinutes),
              shouldInherit = Some(false)
            )
          )

    }

  override def getDevice(deviceId: UUID): Future[Option[ApiDevice]] =
    devicesWithClientCredentials.get(deviceId.toString, Seq())

  override def setFwProperties(deviceId: UUID, fwProperties: FirmwareProperties): Future[Unit] =
    devicesWithClientCredentials.setDeviceProperties(deviceId, fwProperties)
}
