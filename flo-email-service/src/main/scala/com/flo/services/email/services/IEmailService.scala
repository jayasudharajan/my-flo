package com.flo.services.email.services

import com.flo.services.email.models.ActorEmailMessage
import com.sendwithus.model.SendReceipt
import scala.concurrent.Future

trait IEmailClient {
  def send(email: ActorEmailMessage): Future[SendReceipt]
}
