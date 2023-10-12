package com.flo.task.scheduler.services.commands

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.Models.KafkaMessages.SchedulerCommand
import com.flo.task.scheduler.domain.actors.commands.Suspend
import com.flo.task.scheduler.services.BaseActorsSpec
import com.flo.task.scheduler.services.commands.CommandExecutorSupervisor.Executed

class CommandExecutorSpec extends BaseActorsSpec {

  "The CommandExecutor" should {
    "success to run command and notify the parent" in {
      val parent = TestProbe()
      val schedulerInstanceHandler = getInstanceHandler(false)
      val command = SchedulerCommand("suspend", Some(task1.schedule.id))

      val commandExecutorSupervisor = TestActorRef(
        CommandExecutor.props(schedulerInstanceHandler, taskEndpoints),
        parent.ref,
        "CommandExecutor"
      )

      commandExecutorSupervisor ! Suspend(command)
      
      parent.expectMsg(Executed)
    }
  }
}
