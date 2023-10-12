package com.flo.services.email.services

import akka.actor.ActorSystem
import akka.testkit.{ImplicitSender, TestKit}
import com.flo.Models._
import com.flo.Models.KafkaMessages.EmailMessage
import com.flo.Models.Users.UserContactInformation
import com.flo.services.email.models.ActorEmailMessage
import com.sendwithus.exception.SendWithUsException
import com.sendwithus.model.SendReceipt
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}
import scala.concurrent.Future

abstract class BaseEmailActorsSpec extends TestKit(ActorSystem("MySpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll {

  implicit val executionContext = system.dispatcher

  val telemetry = Telemetry(Some(1), Some(2), Some(3), None, None, Some(4), Some(5), None, None, None, None, None, None, None, None, None, None, None)

  val email1 = EmailMessage(
    Some("1"),
    None,
    None,
    Some(
      ICDAlarmNotificationDeliveryRules(
        1,
        true,
        MessageTemplates("smsText", PushNotificationMessage("title", "body"), EmailProperties("subject", "templateId"), "", "", "name"),
        1,
        1,
        None,
        None,
        true,
        None,
        None,
        1,
        None,
        None,
        true
      )
    ),
    Some(ICD(None, None, None, None, None, None)),
    Some(telemetry),
    Some(UserContactInformation(None, None, None, None, None, None, None, None, None, None, Some("someone@gmail.com"), None)),
    Some(Location(None, None, None, None, None, city = Some("LA"), None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None)),
    None,
    None,
    None
  )

  val email2 = EmailMessage(
    Some("2"),
    None,
    None,
    Some(
      ICDAlarmNotificationDeliveryRules(
        1,
        true,
        MessageTemplates("smsText", PushNotificationMessage("title", "body"), EmailProperties("subject", "templateId"), "", "", "name"),
        1,
        1,
        None,
        None,
        true,
        None,
        None,
        1,
        None,
        None,
        true
      )
    ),
    Some(ICD(None, None, None, None, None, None)),
    Some(telemetry),
    Some(UserContactInformation(None, None, None, None, None, None, None, None, None, None, Some("someone2@gmail.com"), None)),
    Some(Location(None, None, None, None, None, city = Some("LA"), None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None)),
    None,
    None,
    None
  )

  override def afterAll(): Unit = {
    TestKit.shutdownActorSystem(system)
  }

  def emailClientThatSuccess = new IEmailClient {
    private var data: List[ActorEmailMessage] = Nil

    def getSavedData = data

    override def send(email: ActorEmailMessage): Future[SendReceipt] = {
      data = email :: data
      Future(new SendReceipt)
    }
  }

  def emailClientThatFailFirstTime = new IEmailClient {
    private var data: List[ActorEmailMessage] = Nil

    private var attempts = 0

    def getAttempts = attempts

    def getSavedData = data.reverse

    override def send(email: ActorEmailMessage): Future[SendReceipt] = {
      attempts = attempts + 1

      if (attempts <= 1) {
        throw new SendWithUsException("ShouldFail error.")
      }

      data = email :: data
      Future(new SendReceipt)
    }
  }
}