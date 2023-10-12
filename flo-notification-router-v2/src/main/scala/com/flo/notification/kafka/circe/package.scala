package com.flo.notification.kafka

import com.flo.notification.router.core.api.activity._
import io.circe.{Decoder, HCursor}

package object circe {

  implicit val entityActivityDecoder: Decoder[EntityActivity] = (c: HCursor) =>
    for {
      id             <- c.downField("id").as[String]
      activityType   <- c.downField("type").as[String]
      activityAction <- c.downField("action").as[String]
      entityId       <- c.downField("item").downField("id").as[String]
    } yield {
      EntityActivity(id, toActivityType(activityType), toActivityAction(activityAction), entityId)
  }

  private def toActivityType(str: String): ActivityType = str match {
    case "device"   => Device
    case "location" => Location
    case "account"  => Account
    case "user"     => User
    case _          => UnknownType
  }

  private def toActivityAction(str: String): ActivityAction = str match {
    case "created" => Created
    case "updated" => Updated
    case "deleted" => Deleted
    case _         => UnknownAction
  }

}
