package com.flo.services.email.services

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.services.email.services.EmailServiceSupervisor.Sent
import com.flo.services.email.utils.SimpleBackoffStrategy

class EmailServiceSpec extends BaseEmailActorsSpec {

  "The EmailService" should {
    "success to send email and notify the parent" in {
      val parent = TestProbe()
      val emailClient = emailClientThatSuccess
      val emailActorMessage = EmailTransformations.toActorEmailMessage(email1)

      val emailServiceSupervisor = TestActorRef(
        EmailService.props(emailClient, new SimpleBackoffStrategy, emailActorMessage),
        parent.ref,
        "EmailService"
      )
      emailServiceSupervisor ! emailActorMessage

      parent.expectMsg(Sent(emailActorMessage))
    }
  }
}