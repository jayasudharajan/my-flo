package Actors

import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.redis.RedisClient
import com.redis.serialization.Parse.Implicits.parseInt

class AlarmRuleEngine(redisClient: RedisClient) {

  private val pointsLimit =  0 //13 //Disable point system
  private val alarmsReached = List(28, 29, 30, 31)
  private val alarmPointsMapping = Map(
    28 -> 13,
    29 -> 13,
    30 -> 5,
    31 -> 3
  )

  private def getRedisKey(deviceId: String): String = {
    s"small-drip:$deviceId"
  }

  private def getCurrentPoints(deviceId: String): Int = {
    val key = getRedisKey(deviceId)
    redisClient.get[Int](key).getOrElse(0)
  }

  private def updatePoints(deviceId: String, pointsSum: Int): Unit = {
    val key = getRedisKey(deviceId)
    val newPoints  = if(pointsSum >= pointsLimit) 0 else pointsSum

    redisClient.set(key, newPoints)
  }

  private def shouldRunEngine(alarmId: Int): Boolean = {
    alarmsReached.contains(alarmId)
  }

  def shouldBeSent(alarmIncident: ICDAlarmIncident): Boolean = {
    val deviceId = alarmIncident.deviceId
    val alarmId = alarmIncident.data.alarm.alarmId

    if(shouldRunEngine(alarmId)) {
      val pointsToRegister = alarmPointsMapping.getOrElse(alarmId, 0)
      val currentPoints = getCurrentPoints(deviceId)
      val pointsSum = currentPoints + pointsToRegister

      updatePoints(deviceId, pointsSum)

      if(pointsSum >= pointsLimit) {
        true
      } else {
        false
      }
    } else {
      true
    }
  }
}
