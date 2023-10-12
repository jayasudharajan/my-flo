package com.flo.communication

import java.net.InetAddress
import java.time.Duration
import java.time.temporal.ChronoUnit
import java.util
import java.util.concurrent.atomic.AtomicBoolean
import java.util.{Date, Properties}

import com.flo.communication.utils.IKafkaConsumerMetrics
import org.apache.kafka.clients.consumer.{CommitFailedException, ConsumerRebalanceListener, KafkaConsumer => Consumer}
import org.apache.kafka.common.TopicPartition
import org.apache.kafka.common.errors.WakeupException
import org.apache.kafka.common.serialization.StringDeserializer
import org.apache.log4j.{Level, Logger}
import org.joda.time.{DateTime, DateTimeZone}

import scala.collection.JavaConverters._
import scala.util.{Failure, Success, Try}

class KafkaConsumer(
                        kafkaHosts: String,
                        groupId: String,
                        topic: String,
                        metrics: IKafkaConsumerMetrics,
                        maxPollRecords: Long = 10,
                        pollTimeout: Long = 3000,
                        messageDecoder: Option[String => String] = None,
                        clientName: Option[String] = None,
                        sessionTimeoutInMilliseconds: Long = 30000
                      ) extends IKafkaConsumer {


  private var consumer: Option[Consumer[String, String]] = None
  private var assignment: List[TopicPartition] = Nil
  private val running = new AtomicBoolean(true)
  private val paused = new AtomicBoolean(false)
  private val topics = List(topic)
  private val autoCommit = false

  private val logger = Logger.getLogger(getClass)

  logger.setLevel(Level.ALL)

  private def getClientId(name: Option[String]): String = name match {
    case Some(value) =>
      InetAddress.getLocalHost.getHostName + "-" + value + "-" + java.util.UUID.randomUUID.toString
    case None =>
      InetAddress.getLocalHost.getHostName + "-" + java.util.UUID.randomUUID.toString
  }

  private def configuration = {
    val keyDeserializer = "org.apache.kafka.common.serialization.StringDeserializer"
    val valueDeserializer = "org.apache.kafka.common.serialization.StringDeserializer"

    val props = new Properties()

    props.put("bootstrap.servers", kafkaHosts)
    props.put("key.deserializer", keyDeserializer)
    props.put("value.deserializer", valueDeserializer)
    props.put("group.id", groupId)
    props.put("session.timeout.ms", sessionTimeoutInMilliseconds.toString)
    props.put("client.id", getClientId(clientName))
    props.put("max.poll.records", maxPollRecords.toString)
    props.put("enable.auto.commit", autoCommit.toString)
    props.put("auto.offset.reset", "earliest")
    props.put("num.consumer.fetchers", "2")
    props.put("rebalance.max.retries", "4")

    props
  }

  def process[T <: AnyRef : Manifest](item: T, timestamp: Long, processor: TopicRecord[T] => Unit): Unit = {
    Try(
      processor(TopicRecord(item, new DateTime(new Date(timestamp)).toDateTime(DateTimeZone.UTC)))
    ) match {
      case Failure(e) =>
        metrics.newProcessorError()
        logger.error("Error when trying to process message", e)

      case Success(_) => metrics.newSuccess()
    }
  }

  def consume[T <: AnyRef : Manifest](deserializer: String => T, processor: TopicRecord[T] => Unit): Unit = {
    consumer = Some(new Consumer[String, String](configuration, new StringDeserializer, new StringDeserializer))
    consumer.get.subscribe(topics.asJava)

    try {
      addEventHandlers()

      while (running.get) {
        if (!paused.get) {
          val records = consumer.get.poll(Duration.of(pollTimeout, ChronoUnit.MILLIS)).asScala

          for (record <- records) {
            val result = Try(deserialize(record.value(), deserializer))

            result match {
              case Failure(e) =>
                metrics.newDeserializationError()
                logger.error("Error when trying to deserialize message", e)

              case Success(item) =>
                process[T](item, record.timestamp(), processor)

            }
          }

          doCommitSync()
        } else {
          Thread.sleep(5000)
        }
      }
    } catch {
      case _: WakeupException => // ignore, we're closing
    } finally {
      consumer.map(x => x.close())
    }
  }

  def pause(): Unit = {
    assignment = consumer.get.assignment().asScala.toList
    consumer.get.pause(assignment.asJava)
    paused.set(true)
  }

  def resume(): Unit = {
    consumer.get.resume(assignment.asJava)
    paused.set(false)
  }

  def isPaused(): Boolean = {
    paused.get
  }

  protected def deserialize[T <: AnyRef](message: String, deserializer: String => T): T = {
    val toDeserialize = messageDecoder match {
      case Some(f) => f(message)
      case None => message
    }

    deserializer(toDeserialize)
  }

  private def addEventHandlers(): Unit = {
    consumer.get.subscribe(topics.asJava, new ConsumerRebalanceListener() {
      @Override
      def onPartitionsRevoked(partitions: util.Collection[TopicPartition]): Unit = {
        doCommitSync()
      }

      @Override
      override def onPartitionsAssigned(partitions: util.Collection[TopicPartition]): Unit = {}
    })
  }

  private def doCommitSync(): Unit = {
    try {
      consumer.map(x => x.commitSync())
    } catch {
      case e: WakeupException =>
        // we're shutting down, but finish the commit first and then
        // rethrow the exception so that the main loop can exit
        doCommitSync()
        throw e
      case e: CommitFailedException =>
        // the commit failed with an unrecoverable error. if there is any
        // internal state which depended on the commit, you can clean it
        // up here. otherwise it's reasonable to ignore the error and go on
        logger.debug("Commit failed", e);
    }
  }

  def shutdown(): Unit = {
    running.set(false)
    paused.set(false)
    consumer foreach { x =>
      x.wakeup()
    }
    consumer = None
  }
}
