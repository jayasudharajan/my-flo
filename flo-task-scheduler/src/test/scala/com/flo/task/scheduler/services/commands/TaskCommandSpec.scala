package com.flo.task.scheduler.services.commands

import com.flo.Models.KafkaMessages.{Schedule, Task}
import org.scalatest.{Matchers, WordSpec, WordSpecLike}

class TaskCommandSpec extends WordSpec with WordSpecLike with Matchers {

  "The TaskCommand" should {
    "return true on isOneTimer on en task to be execute in an exact date/time" in {
      val taskCommand = Task(
        "onetopic",
        "data1",
        Schedule(
          "1",
          Some("weeklyReport"),
          "0 39 0 26 AUG ? 2016",
          "America/Los_Angeles",
          None,
          None
        )
      )

      taskCommand.isOneTimer shouldEqual true
    }

    "return false on isOneTimer on task to be executed every 30 seconds" in {
      val taskCommand = Task(
        "onetopic",
        "data1",
        Schedule(
          "1",
          Some("weeklyReport"),
          "*/30 * * ? * *",
          "America/Los_Angeles",
          None,
          None
        )
      )

      taskCommand.isOneTimer shouldEqual false
    }
  }
}