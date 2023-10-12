package com.flo.notification.router.core.api

case class NameAndFallback(name: String, fallback: Option[String])
case class DeliveryMediumTemplate(body: NameAndFallback, subject: Option[NameAndFallback])
