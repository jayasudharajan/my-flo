package com.flo.services.email.services

import akka.testkit.TestProbe
import scala.concurrent.duration._

class EmailServiceSupervisorSpec extends BaseEmailActorsSpec {

  "The EmailServiceSupervisor" should {
    "success to send email at first attempt" in {
      val proxy = TestProbe()
      val emailClient = emailClientThatSuccess
      val emailServiceSupervisor = system.actorOf(EmailServiceSupervisor.props(emailClient))
      val emailActorMessage = EmailTransformations.toActorEmailMessage(email1)

      proxy.send(emailServiceSupervisor, emailActorMessage)

      awaitAssert({
        emailClient.getSavedData.find(m => m == emailActorMessage) shouldEqual Some(emailActorMessage)
      }, 1.second, 100.milliseconds)
    }

    "fails the first attempt but success to send email at second attempt" in {
      val proxy = TestProbe()
      val emailClient = emailClientThatFailFirstTime
      val telemetryDumperSupervisor = system.actorOf(EmailServiceSupervisor.props(emailClient))
      val emailActorMessage = EmailTransformations.toActorEmailMessage(email1)

      proxy.send(telemetryDumperSupervisor, emailActorMessage)

      awaitAssert({
        emailClient.getSavedData.length shouldEqual 1
        emailClient.getAttempts shouldEqual 2

        emailClient.getSavedData.find(m => m == emailActorMessage) shouldEqual Some(emailActorMessage)
      }, 6.second, 100.milliseconds)
    }
  }
}