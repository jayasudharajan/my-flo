package com.flo.notification.router.core.filter

import java.net.InetAddress
import java.time.{Clock, Duration}

import akka.actor.ActorSystem
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api.{AlarmIncidentFilter => CoreAlarmIncidentFilter, _}
import com.typesafe.config.Config
import redis.{RedisCluster, RedisServer}

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def rootConfig: Config
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def defaultClock: Clock
  def retrieveDoNotDisturbSettings: DoNotDisturbSettingsRetriever
  def retrieveFrequencyCapExpiration: FrequencyCapExpirationRetriever
  def retrieveSnoozeTime: SnoozeTimeRetriever
  def retrieveDeliverySettings: DeliverySettingsRetriever
  def retrieveUserAlarmSettings: UserAlarmSettingsRetriever

  // Private
  private val redisConfig: Config = rootConfig.getConfig("redis")
  private val redisCluster = RedisCluster(InetAddress.getAllByName(redisConfig.getString("host")).map { address =>
    RedisServer(address.getHostAddress, redisConfig.getInt("port"))
  })(actorSystem)

  private val alarmExpiration = appConfig.as[Duration]("alarm-filters.expiration-filter.alarm-expiration")

  private val expirationFilter = new ExpirationFilter(defaultClock, alarmExpiration)

  private val alarmSettingsFilter = new AlarmSettingsFilter()

  private val alarmPointSystemFilter = new AlarmPointSystemFilter(redisCluster)(defaultExecutionContext)

  private val maxDeliveryFrequencyFilter =
    new MaxDeliveryFrequencyFilter(defaultClock, retrieveFrequencyCapExpiration)(defaultExecutionContext)

  private val snoozeFilter = new SnoozeFilter(defaultClock, retrieveSnoozeTime)(defaultExecutionContext)

  private val shutoffExceptions = appConfig.as[Set[AlarmId]]("alarm-filters.flo-sense-filter.shutoff-exceptions")
  private val floSenseAlarms    = appConfig.as[Set[AlarmId]]("alarm-filters.flo-sense-filter.flo-sense-alarms")
  private val floSenseFilter    = new FloSenseFilter(shutoffExceptions, floSenseAlarms)

  private val deliverySettingsFilter = new DeliverySettingsFilter(retrieveDeliverySettings)(defaultExecutionContext)

  private val smallDripSensitivityFilter =
    new SmallDripSensitivityFilter(retrieveUserAlarmSettings)(defaultExecutionContext)

  private val sleepModeExceptions = appConfig.as[Set[AlarmId]]("alarm-filters.sleep-mode-filter.exceptions")
  private val sleepModeFilter     = new SleepModeFilter(sleepModeExceptions)

  private val alarmsMuteFilter = new AlarmsMuteFilter(retrieveDeliverySettings)(defaultExecutionContext)

  private val filters: List[AlarmIncidentFilter] = List(
    expirationFilter,
    alarmsMuteFilter,
    maxDeliveryFrequencyFilter,
    sleepModeFilter,
    alarmSettingsFilter,
    snoozeFilter,
    smallDripSensitivityFilter,
    alarmPointSystemFilter,
    floSenseFilter,
    deliverySettingsFilter
  )

  // Provides
  val applyAlarmIncidentFilters: CoreAlarmIncidentFilter =
    new AlarmIncidentFilters(filters)(defaultExecutionContext).apply _
}
