package flo.services.sms.services

import akka.actor.SupervisorStrategy.{Directive, Restart, Stop}
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.twilio.exception.{ApiConnectionException, ApiException, InvalidRequestException}
import flo.services.sms.domain.Sms
import flo.services.sms.services.SmsServiceSupervisor.Sent
import flo.services.sms.utils._

class SmsServiceSupervisor(smsClient: SmsClient) extends Actor with ActorLogging {

  log.info("SmsServiceSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: UnrecoverableTwilioError => handleStop(e)
    case e: InvalidRequestException => handleStop(e)
    case e: ApiConnectionException => handleRestart(e)
    case e: ApiException => handleRestart(e)
    case e: Throwable => handleStop(e)
  }

  def handleStop(e: Throwable): Directive = {
    log.error(e, "Unrecoverable failure, will not retry.")
    Stop
  }

  def handleRestart(e: Throwable): Directive = {
    log.error(e, "There was an error when trying to send the sms, retrying.")
    Restart
  }

  def receive = {

    case sms: Sms =>
      //Actor per request pattern, see:
      //http://techblog.net-a-porter.com/2013/12/ask-tell-and-per-request-actors/
      //http://stackoverflow.com/a/13809135/2429533 see edit2
      //http://stackoverflow.com/a/13811579/2429533 see the time to create a new actor
      //This pattern is used a lot with spray or akka-http
      val smsService = context.actorOf(SmsService.props(smsClient, new SimpleBackoffStrategy, sms))
    case Sent(sms) =>
      //Make some post process
  }
}

object SmsServiceSupervisor {
  def props(smsClient: SmsClient) = Props(classOf[SmsServiceSupervisor], smsClient)

  case class Sent(sms: Sms)
}




