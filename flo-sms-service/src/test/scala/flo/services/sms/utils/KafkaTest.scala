/*
package flo.services.sms.utils

import java.io.File
import java.util.{Arrays, Properties}
import javax.security.auth.login.Configuration
import kafka.common.KafkaException
import kafka.server.{KafkaConfig, KafkaServer}
import kafka.utils.{CoreUtils, TestUtils, ZkUtils}
import kafka.zk.{EmbeddedZookeeper, ZkFourLetterWords}
import org.apache.kafka.common.protocol.SecurityProtocol
import org.apache.kafka.common.security.JaasUtils
import org.apache.kafka.common.security.auth.KafkaPrincipal
import org.scalatest.{BeforeAndAfter, Matchers, WordSpec}
import scala.collection.mutable.Buffer

abstract class KafkaTest extends WordSpec with Matchers with BeforeAndAfter {
  val zkConnectionTimeout = 6000
  val zkSessionTimeout = 6000

  var zkUtils: ZkUtils = null
  var zookeeper: EmbeddedZookeeper = null

  def zkPort: Int = zookeeper.port
  def zkConnect: String = s"127.0.0.1:$zkPort"

  var instanceConfigs: Seq[KafkaConfig] = null
  var servers: Buffer[KafkaServer] = null
  var brokerList: String = null
  var alive: Array[Boolean] = null
  val kafkaPrincipalType = KafkaPrincipal.USER_TYPE
  val setClusterAcl: Option[() => Unit] = None

  /**
    * Implementations must override this method to return a set of KafkaConfigs. This method will be invoked for every
    * test and should not reuse previous configurations unless they select their ports randomly when servers are started.
    */
  def generateConfigs(): Seq[KafkaConfig]

  def configs: Seq[KafkaConfig] = {
    if (instanceConfigs == null)
      instanceConfigs = generateConfigs()
    instanceConfigs
  }

  def serverForId(id: Int) = servers.find(s => s.config.brokerId == id)

  protected def securityProtocol: SecurityProtocol = SecurityProtocol.PLAINTEXT
  protected def trustStoreFile: Option[File] = None
  protected def saslProperties: Option[Properties] = None

  before {
    //Create Zookeeper server
    zookeeper = new EmbeddedZookeeper()
    zkUtils = ZkUtils(zkConnect, zkSessionTimeout, zkConnectionTimeout, JaasUtils.isZkSecurityEnabled())

    //Create Kafka servers
    if (configs.size <= 0)
      throw new KafkaException("Must supply at least one server config.")
    servers = configs.map(TestUtils.createServer(_)).toBuffer
    brokerList = TestUtils.getBrokerListStrFromServers(servers, securityProtocol)
    alive = new Array[Boolean](servers.length)
    Arrays.fill(alive, true)
    // We need to set a cluster ACL in some cases here
    // because of the topic creation in the setup of
    // IntegrationTestHarness. If we don't, then tests
    // fail with a cluster action authorization exception
    // when processing an update metadata request
    // (controller -> broker).
    //
    // The following method does nothing by default, but
    // if the test case requires setting up a cluster ACL,
    // then it needs to be implemented.
    setClusterAcl.foreach(_.apply)
  }

  after {
    //Shutdown Kafka servers
    if (servers != null) {
      servers.foreach(_.shutdown())
      servers.foreach(server => CoreUtils.delete(server.config.logDirs))
    }

    //Shutdown Zookeeper server
    if (zkUtils != null)
      CoreUtils.swallow(zkUtils.close())
    if (zookeeper != null)
      CoreUtils.swallow(zookeeper.shutdown())

    def isDown(): Boolean = {
      try {
        ZkFourLetterWords.sendStat("127.0.0.1", zkPort, 3000)
        false
      } catch { case _: Throwable =>
        true
      }
    }

    Iterator.continually(isDown()).exists(identity)

    Configuration.setConfiguration(null)
  }

  /**
    * Pick a broker at random and kill it if it isn't already dead
    * Return the id of the broker killed
    */
  def killRandomBroker(): Int = {
    val index = TestUtils.random.nextInt(servers.length)
    if(alive(index)) {
      servers(index).shutdown()
      servers(index).awaitShutdown()
      alive(index) = false
    }
    index
  }

  /**
    * Restart any dead brokers
    */
  def restartDeadBrokers(): Unit = {
    for(i <- 0 until servers.length if !alive(i)) {
      servers(i).startup()
      alive(i) = true
    }
  }
}
*/
