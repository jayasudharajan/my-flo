package com.flo.task.scheduler.domain.actors.commands

abstract class Command

object Command {
  val cancel = "cancel"
  val suspend = "suspend"
  val suspendAll = "suspend-all"
  val resume = "resume"
  val resumeAll = "resume-all"
}
