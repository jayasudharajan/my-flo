package com.flo.notification.sdk.model

case class Alarm (
  id: Int,
  name: String,
  severity: Int,
  isInternal: Boolean,
  sendWhenValveIsClosed: Boolean,
  enabled: Boolean,
  userConfigurable: Boolean,
  maxDeliveryFrequency: String,
  parentId: Option[Int],
  children: Set[Int] = Set(),
  metadata: Map[String, Any],
  tags: Set[String],
  userFeedbackOptionsId: Option[Int]
)