package com.flo.notification.router.core.filter

import akka.util.ByteString
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import perfolation._
import redis.{ByteStringDeserializer, RedisCluster}

import scala.concurrent.{ExecutionContext, Future}

final private class AlarmPointSystemFilter(redis: RedisCluster)(implicit ec: ExecutionContext)
    extends AlarmIncidentFilter {

  implicit private object IntDeserializer extends ByteStringDeserializer[Int] {
    def deserialize(bs: ByteString): Int = bs.utf8String.toInt
  }

  private val pointsLimit   = 13
  private val alarmsReached = Set(28, 29, 30, 31)
  private val alarmPointsMapping = Map(
    28 -> 13,
    29 -> 13,
    30 -> 5,
    31 -> 3
  )

  private def getRedisKey(deviceId: String): String =
    p"small-drip:$deviceId"

  private def getCurrentPoints(deviceId: String): Future[Int] = {
    val key = getRedisKey(deviceId)
    redis.get[Int](key).map(_.getOrElse(pointsLimit + 1))
  }

  private def updatePoints(deviceId: String, pointsSum: Int): Future[Boolean] = {
    val key       = getRedisKey(deviceId)
    val newPoints = if (pointsSum >= pointsLimit) 0 else pointsSum

    redis.set(key, newPoints)
  }

  private def shouldRunEngine(alarmId: Int): Boolean =
    alarmsReached.contains(alarmId)

  private def shouldBeSent(alarmIncident: AlarmIncident): Future[Boolean] = {
    val deviceId = alarmIncident.macAddress
    val alarmId  = alarmIncident.alarmId

    if (shouldRunEngine(alarmId)) {
      val pointsToRegister    = alarmPointsMapping.getOrElse(alarmId, 0)
      val currentPointsResult = getCurrentPoints(deviceId)

      currentPointsResult.flatMap { currentPoints =>
        val pointsSum = currentPoints + pointsToRegister

        updatePoints(deviceId, pointsSum).map { _ =>
          pointsSum >= pointsLimit
        }
      }
    } else {
      Future.successful(true)
    }
  }

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    //TODO: We disable this in V1 and V2 for now per product request
    Future.successful(AllMediumsAllowed)
  /*
    shouldBeSent(alarmIncident).map { send =>
      if (send) AllMediumsAllowed
      else NoMediumsAllowed(PointsLimitNotReachedForCategory)
    }
 */
}
