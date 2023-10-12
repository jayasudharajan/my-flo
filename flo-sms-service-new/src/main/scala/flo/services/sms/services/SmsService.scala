package flo.services.sms.services

import akka.actor.{Actor, ActorLogging, Props}
import SmsServiceSupervisor.Sent
import flo.services.sms.domain.Sms
import flo.services.sms.utils.{BackoffStrategy, SmsClient}

class SmsService(smsClient: SmsClient, backoffStrategy: BackoffStrategy, sms: Sms) extends Actor with ActorLogging {

  import context.dispatcher

  override def preStart(): Unit = {
    context.system.scheduler.scheduleOnce(backoffStrategy.backoffTime, self, sms)
    backoffStrategy.increment()
  }

  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created. In this case smsClient, backoffStrategy and sms.
  def receive = {
    case sms: Sms =>
      smsClient.send(sms)
      backoffStrategy.reset()

      //indicate to supervisor that the operation was a success
      context.parent ! Sent(sms)
      // Don't forget to stop the actor after it has nothing more to do
      context.stop(self)
  }
}

object SmsService {
  def props(smsClient: SmsClient, backoffStrategy: BackoffStrategy, sms: Sms) = Props(classOf[SmsService], smsClient, backoffStrategy, sms)
}


