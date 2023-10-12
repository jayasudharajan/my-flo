package com.flo.task.scheduler.services.commands

import akka.testkit.TestProbe
import com.flo.task.scheduler.services.BaseActorsSpec
import scala.concurrent.duration._

class CommandExecutorSupervisorSpec extends BaseActorsSpec {

  "The CommandExecutorSupervisor" should {
    "success to run command at first attempt" in {
      val proxy = TestProbe()
      val schedulerInstanceHandler = getInstanceHandler(false)
      val commandExecutorSupervisor = system.actorOf(
        CommandExecutorSupervisor.props(schedulerInstanceHandler, taskEndpoints)
      )

      proxy.send(commandExecutorSupervisor, command1)

      awaitAssert({
        schedulerInstanceHandler
          .getReal()
          .getCommands
          .find(m => m == executorCommand1) shouldEqual Some(executorCommand1)
      }, 2.second, 100.milliseconds)
    }
  }
}