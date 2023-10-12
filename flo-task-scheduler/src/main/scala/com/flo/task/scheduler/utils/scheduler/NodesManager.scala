package com.flo.task.scheduler.utils.scheduler

import org.redisson.api.RScheduledExecutorService

trait NodesManager {
  def getOwnedNodeId(): String
  def getExecutorServiceByNode(nodeId: String): RScheduledExecutorService
  def getExecutorServiceName(nodeId: String): String
}
