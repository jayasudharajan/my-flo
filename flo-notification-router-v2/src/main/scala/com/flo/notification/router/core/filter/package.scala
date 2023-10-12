package com.flo.notification.router.core

import cats.Order
import com.flo.notification.router.core.api.DeliveryMedium

package object filter {
  implicit def ordering[A <: DeliveryMedium]: Order[A] = Order.from((a, b) => a.getId.compareTo(b.getId))
}
