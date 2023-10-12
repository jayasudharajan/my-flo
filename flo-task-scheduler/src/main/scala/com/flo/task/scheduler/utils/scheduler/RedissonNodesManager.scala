package com.flo.task.scheduler.utils.scheduler

import com.flo.task.scheduler.utils._
import com.redis.RedisClientPool
import org.redisson.RedissonNode
import org.redisson.api.RScheduledExecutorService
import org.redisson.config.RedissonNodeConfig

import scala.collection.JavaConverters._

class RedissonNodesManager(
                           taskSchedulerId: String,
                           val redisHost: String,
                           val redisPort: Int,
                           numberOfExecutorServices: Int = 1,
                           timeToBeDeadInMillis: Long = 15000
                         ) extends NodesManager with RedissonInstanceHelpers with UUIDGenerator with Logging {

  private var redissonNode: Option[RedissonNode] = None

  val redisPool = new RedisClientPool(redisHost, redisPort)
  val random = scala.util.Random
  val numberOfServiceWorkers = 1
  val nodeIds: List[String] = generateNodes()


  private def generateNodes(): List[String] = {
    (1 to numberOfExecutorServices)
      .map(nodeNumber => s"$taskSchedulerId:node-$nodeNumber")
      .toList
  }

  def getExecutorServiceName(nodeId: String): String = {
    s"redisson-executor-service:$nodeId"
  }

  def getExecutorServiceByNode(nodeId: String): RScheduledExecutorService = {
    getExecutorServiceByName(getExecutorServiceName(nodeId))
  }

  def runOwnedNodes(): Unit = {
    val redissonNodeConfig = new RedissonNodeConfig(getRedissonConfig())

    logger.info("Redisson node will be restarted to load new owned scheduler nodeIds.")
    redissonNode.map(node => node.shutdown())

    logger.info(
      s"The following nodeIds will added to redisson node config: ${nodeIds.map(nodeId => nodeId).mkString(", ")}"
    )

    val executorsConfig = nodeIds
      .map(nodeId => (getExecutorServiceName(nodeId) -> numberOfServiceWorkers.asInstanceOf[Integer])).toMap

    redissonNodeConfig.setExecutorServiceWorkers(executorsConfig.asJava)

    redissonNode = Some(RedissonNode.create(redissonNodeConfig))

    redissonNode.map(node => node.start())
  }

  def getOwnedNodeId(): String = {
    val numberOfNodes = nodeIds.size
    val nodeIndex = random.nextInt(numberOfNodes)

    nodeIds(nodeIndex)
  }
}