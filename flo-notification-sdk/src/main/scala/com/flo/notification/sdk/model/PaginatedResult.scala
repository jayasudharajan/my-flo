package com.flo.notification.sdk.model

case class PaginatedResult[T](items: List[T], total: Long)
