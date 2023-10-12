package com.flo.services.email.services

import akka.actor.SupervisorStrategy.{Restart, Stop}
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.flo.services.email.models.ActorEmailMessage
import com.flo.services.email.services.EmailServiceSupervisor.Sent
import com.flo.services.email.utils.SimpleBackoffStrategy
import com.sendwithus.exception.SendWithUsException

class EmailServiceSupervisor(emailClient: IEmailClient) extends Actor with ActorLogging {

  log.info("EmailServiceSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: SendWithUsException =>
      //If enter here the action will be retry
      log.error("There was an error when trying to send the email, restarting.")
      Restart
    case e: Exception =>
      //If enter here the action will be cancelled, in this case not will send the email
      log.error("Unexpected failure: {}", e.getMessage)
      Stop
  }

  def receive = {
    case email: ActorEmailMessage =>
      //Actor per request pattern, see:
      //http://techblog.net-a-porter.com/2013/12/ask-tell-and-per-request-actors/
      //http://stackoverflow.com/a/13809135/2429533 see edit2
      //http://stackoverflow.com/a/13811579/2429533 see the time to create a new actor
      //This pattern is used a lot with spray or akka-http
      context.actorOf(EmailService.props(emailClient, new SimpleBackoffStrategy, email))
    case Sent(email) =>
      //Make some post process
  }
}

object EmailServiceSupervisor {
  def props(emailService: IEmailClient) = Props(classOf[EmailServiceSupervisor], emailService)

  case class Sent(emailMessage: ActorEmailMessage)
}




