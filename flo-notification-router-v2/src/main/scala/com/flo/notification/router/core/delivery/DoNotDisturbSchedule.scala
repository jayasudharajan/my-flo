package com.flo.notification.router.core.delivery

import java.time.OffsetDateTime
import com.flo.notification.router.core.api.DeliveryMedium

case class DoNotDisturbSchedule(mediums: List[DeliveryMedium], time: OffsetDateTime)
