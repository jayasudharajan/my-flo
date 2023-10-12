package com.flo.notification.router.core.api

case class Location(id: String,
                    address: String,
                    address2: Option[String],
                    city: String,
                    state: Option[String],
                    country: String,
                    postalCode: String,
                    timezone: String,
                    nickname: Option[String])
