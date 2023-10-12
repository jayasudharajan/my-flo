package com.flo.push.core.api

case class UserNotificationTokens(userId: String, androidTokens: Set[String], iosTokens: Set[String])