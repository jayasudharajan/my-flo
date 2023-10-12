package com.flo.services.email.services

import akka.actor.{Actor, ActorLogging, Props}
import com.flo.services.email.models.ActorEmailMessage
import com.flo.services.email.services.EmailServiceSupervisor.Sent
import com.flo.services.email.utils.BackoffStrategy

class EmailService(emailClient: IEmailClient, backoffStrategy: BackoffStrategy, email: ActorEmailMessage)
  extends Actor with ActorLogging {

  import context.dispatcher

  override def preStart(): Unit = {
    context.system.scheduler.scheduleOnce(backoffStrategy.backoffTime, self, email)
    backoffStrategy.increment()
  }

  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created. In this case emailClient, backoffStrategy and email.
  def receive = {
    case email: ActorEmailMessage =>
      //TODO: What happen is there is an error when we post to the flo api, we need to think a good solution
      emailClient.send(email)

      backoffStrategy.reset()

      //indicate to supervisor that the operation was a success
      context.parent ! Sent(email)
      // Don't forget to stop the actor after it has nothing more to do
      context.stop(self)
  }
}

object EmailService {
  def props(emailClient: IEmailClient, backoffStrategy: BackoffStrategy, email: ActorEmailMessage) =
    Props(classOf[EmailService], emailClient, backoffStrategy, email)
}


