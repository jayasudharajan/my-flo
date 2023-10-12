package com.flo.notification.sdk.model

import io.getquill.Embedded

sealed trait FeedbackOptionType
case object ListType extends FeedbackOptionType {
  override def toString: String = "list"
}
case object CardType extends FeedbackOptionType {
  override def toString: String = "card"
}

case object ItemType extends FeedbackOptionType {
  override def toString: String = "item"
}

case object TextType extends FeedbackOptionType {
  override def toString: String = "text"
}

case class FeedbackOptionIcon(tag: String, imageUrl: String)

case class FeedbackOption(id: String,
                          `type`: FeedbackOptionType,
                          displayName: Option[String],
                          displayTitle: Option[String],
                          value: String,
                          sortOrder: Option[Int],
                          sortRandom: Option[Boolean],
                          icon: Option[FeedbackOptionIcon],
                          options: Option[Seq[FeedbackOption]],
                          optionsKey: Option[String]) extends Embedded

case class UserFeedbackOptions(id: Int, feedback: FeedbackOption, optionsKeyList: Seq[FeedbackOption]) extends Embedded
