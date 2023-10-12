package com.flo.notification.router.core.api

sealed trait AccountType
case object Personal   extends AccountType
case object Enterprise extends AccountType

case class Account(id: String, accountType: AccountType = Personal)
