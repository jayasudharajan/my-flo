package com.flo.task.scheduler.services.tasks

import akka.testkit.TestProbe
import com.flo.task.scheduler.domain.actors.commands.Schedule
import com.flo.task.scheduler.services.BaseActorsSpec
import scala.concurrent.duration._

class TaskExecutorSupervisorSpec extends BaseActorsSpec {

  "The TaskExecutorSupervisor" should {
    "success to run command at first attempt" in {
      val proxy = TestProbe()
      val schedulerInstanceHandler = getInstanceHandler(false)
      val repository = getKafkaProducerRepository
      val taskExecutorSupervisor = system.actorOf(
        TaskExecutorSupervisor.props(schedulerInstanceHandler, repository, taskEndpoints)
      )

      proxy.send(taskExecutorSupervisor, Schedule(task1))

      awaitAssert({
        schedulerInstanceHandler.getReal().getTasks.find(m => m == task1) shouldEqual Some(task1)

        repository.producer.getMessages.find(
          m => m == task1.taskData
        ) shouldEqual Some(task1.taskData)

      }, 2.second, 100.milliseconds)
    }
  }
}