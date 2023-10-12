package com.flo.task.scheduler.utils.scheduler

case class DuplicatedTaskIdException() extends Exception("Task id must be unique.")
