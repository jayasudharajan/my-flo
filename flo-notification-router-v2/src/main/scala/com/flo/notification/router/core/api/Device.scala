package com.flo.notification.router.core.api

case class Device(id: String,
                  macAddress: String,
                  location: Location,
                  floSenseLevel: Option[Int],
                  nickname: Option[String])
