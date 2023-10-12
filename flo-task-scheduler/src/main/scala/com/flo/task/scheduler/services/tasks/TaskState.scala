package com.flo.task.scheduler.services.tasks

object TaskState extends Enumeration {
  type TaskState = Value with Matching

  val SCHEDULED = MyValue("scheduled")
  val CANCELED = MyValue("canceled")
  val RESUMED = MyValue("resumed")
  val ALL_RESUMED = MyValue("all-resumed")
  val SUSPENDED = MyValue("suspended")
  val ALL_SUSPENDED = MyValue("all-suspended")
  val EXECUTED = MyValue("executed")

  def MyValue(name: String): Value with Matching =
    new Val(nextId, name) with Matching

  // enables matching against all TaskState.Values
  def unapply(s: String): Option[Value] =
    values.find(s == _.toString)

  trait Matching {
    // enables matching against a particular TaskState.Value
    def unapply(s: String): Boolean =
      (s == toString)
  }
}
