package com.flo.notification.router.core.api

case class Sms(incidentId: String, userId: String, phoneNumber: String, text: String)
