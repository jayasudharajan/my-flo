package com.flo.notification.sdk.model

case class AlertFeedbackStepOption(property: String, displayText: Option[String], sortOrder: Option[Int], sortRandom: Option[Boolean], action: Option[String], value: AnyVal, flow: Option[Either[TaggedAlertFeedbackStep, AlertFeedbackStep]])

case class TaggedAlertFeedbackStep(tag: String)

case class AlertFeedbackStep(`type`: String, titleText: String, options: Seq[AlertFeedbackStepOption])

case class AlertFeedbackFlow(alarmId: Int, systemMode: Int, flow: AlertFeedbackStep, flowTags: Map[String, AlertFeedbackStep])
