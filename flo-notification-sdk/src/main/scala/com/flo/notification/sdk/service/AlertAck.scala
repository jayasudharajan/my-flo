package com.flo.notification.sdk.service

case class Alert(id: Int, severity: String)

case class AlertAck(id: String, alert: Alert, status: String, reason: String, processedAt: String)
