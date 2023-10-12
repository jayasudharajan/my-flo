package com.flo.notification.router.core.api

import scala.concurrent.Future

package object delivery {
  type KafkaSender = (String, String) => Future[Unit]
}
