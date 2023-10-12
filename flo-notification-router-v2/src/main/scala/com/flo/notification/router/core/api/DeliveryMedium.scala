package com.flo.notification.router.core.api

sealed trait DeliveryMedium {
  def getId: Int

  // By default, Scala doesn't use the class of Products for computing hashCode. The consequence is that, for example
  // `EmailMedium.hashCode == SmsMedium.hashCode`, which isn't what we want in this particular implementation.
  override def hashCode: Int = runtime.ScalaRunTime._hashCode((this.getClass, getId))
}

case object EmailMedium extends DeliveryMedium {
  override def getId: DeliveryMediumId = 2

  override def toString = "email"
}

case object PushNotificationMedium extends DeliveryMedium {
  override def getId: DeliveryMediumId = 3

  override def toString = "push"
}

case object SmsMedium extends DeliveryMedium {
  override def getId: DeliveryMediumId = 4

  override def toString = "sms"
}

case object VoiceCallMedium extends DeliveryMedium {
  override def getId: DeliveryMediumId = 5

  override def toString = "voice"
}
