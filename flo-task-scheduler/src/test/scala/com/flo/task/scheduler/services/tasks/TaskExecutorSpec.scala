package com.flo.task.scheduler.services.tasks

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.task.scheduler.domain.actors.Executed
import com.flo.task.scheduler.services.BaseActorsSpec

class TaskExecutorSpec extends BaseActorsSpec {

  "The TaskExecutor" should {
    "success to run command and notify the parent" in {
      val parent = TestProbe()
      val schedulerInstanceHandler = getInstanceHandler(false)

      val taskExecutorSupervisor = TestActorRef(
        TaskExecutor.props(schedulerInstanceHandler, getKafkaProducerRepository, taskEndpoints),
        parent.ref,
        "TaskExecutor"
      )

      taskExecutorSupervisor ! task1

      parent.expectMsg(Executed(task1))
    }
  }
}