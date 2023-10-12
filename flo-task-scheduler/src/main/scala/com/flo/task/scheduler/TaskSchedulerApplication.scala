package com.flo.task.scheduler

import akka.actor.{ActorSystem, CoordinatedShutdown, OneForOneStrategy, SupervisorStrategy}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.TaskSchedulerEndpoints
import com.flo.Models.KafkaMessages.{SchedulerCommand, Task}
import com.flo.communication.{KafkaConsumer, KafkaProducer}
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.encryption.{EncryptionPipeline, FLOCipher, KeyIdRotationStrategy, S3RSAKeyProvider}
import com.flo.task.scheduler.services.KafkaProducerRepository
import com.flo.task.scheduler.services.commands.CommandsConsumer
import com.flo.task.scheduler.services.tasks.TasksConsumer
import com.flo.task.scheduler.utils._
import com.flo.utils.{FromCamelToSneakCaseSerializer, FromSneakToCamelCaseDeserializer, HttpMetrics}
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon

import scala.concurrent.Await
import scala.concurrent.duration._

object TaskSchedulerApplication extends App with LazyLogging {

  Kamon.start()

  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("task-scheduler-system")
  implicit val materializer = ActorMaterializer()
  implicit val executionContext = system.dispatcher

  logger.info("Actor system was created for Task Scheduler")

  val cipher = new FLOCipher
  val keyProvider = new S3RSAKeyProvider(
    ConfigUtils.cipher.keyProvider.bucketRegion,
    ConfigUtils.cipher.keyProvider.bucketName,
    ConfigUtils.cipher.keyProvider.keyPathTemplate
  )
  val rotationStrategy = new KeyIdRotationStrategy
  val encryptionPipeline = new EncryptionPipeline(cipher, keyProvider, rotationStrategy)

  val decryptFunction = (message: String) => encryptionPipeline.decrypt(message)

  val kafkaProducerRepository = new KafkaProducerRepository(
    topic => new KafkaProducer(
      ConfigUtils.kafka.host,
      topic
    )
  )

  val serializer = new FromCamelToSneakCaseSerializer
  val deserializer = new FromSneakToCamelCaseDeserializer

  val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  val taskSchedulerInstanceHandler = new TaskSchedulerInstanceHandler(
    ConfigUtils.scheduler.id,
    ConfigUtils.redis.host,
    ConfigUtils.redis.port,
    ConfigUtils.scheduler.numberOfExecutorServices
  )

  val taskSchedulerEndpoints = new TaskSchedulerEndpoints(httpMetrics)

  implicit val tasksKafkaConsumerMetrics = Kamon.metrics.entity(
    KafkaConsumerMetrics,
    ConfigUtils.kafka.topics.tasks,
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  //Task consumer/executor configuration
  val tasksKafkaConsumer = new KafkaConsumer(
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId,
    ConfigUtils.kafka.topics.tasks,
    tasksKafkaConsumerMetrics,
    messageDecoder = if(ConfigUtils.kafka.encryption) Some(decryptFunction) else None,
    clientName = Some("task-scheduler"),
    maxPollRecords = ConfigUtils.kafka.maxPollRecords,
    pollTimeout = ConfigUtils.kafka.pollTimeout
  )

  val tasksConsumerProps = TasksConsumer.props(
    tasksKafkaConsumer,
    kafkaProducerRepository,
    x => deserializer.deserialize[Task](x),
    taskSchedulerInstanceHandler,
    taskSchedulerEndpoints,
    ConfigUtils.kafka.filterTimeInSeconds
  )

  val tasksConsumerSupervisor = BackoffSupervisor.props(
    Backoff.onStop(
      tasksConsumerProps,
      childName = "tasks-consumer",
      minBackoff = 3.seconds,
      maxBackoff = 30.seconds,
      randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
    ).withSupervisorStrategy(
      OneForOneStrategy() {
        case ex =>
          system.log.error("There was an error in TasksConsumer", ex)
          SupervisorStrategy.Restart //Here we can add some log or send a notification
      })
  )

  system.actorOf(tasksConsumerSupervisor)

  implicit val schedulerCommandsKafkaConsumerMetrics = Kamon.metrics.entity(
    KafkaConsumerMetrics,
    ConfigUtils.kafka.topics.tasks,
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  //Scheduler command consumer/executor configuration
  val schedulerCommandsKafkaConsumer = new KafkaConsumer(
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId,
    ConfigUtils.kafka.topics.schedulerCommands,
    schedulerCommandsKafkaConsumerMetrics,
    messageDecoder = if(ConfigUtils.kafka.encryption) Some(decryptFunction) else None,
    clientName = Some("task-scheduler"),
    maxPollRecords = ConfigUtils.kafka.maxPollRecords,
    pollTimeout = ConfigUtils.kafka.pollTimeout
  )

  val schedulerCommandsConsumerProps = CommandsConsumer.props(
    schedulerCommandsKafkaConsumer,
    x => deserializer.deserialize[SchedulerCommand](x),
    taskSchedulerInstanceHandler,
    taskSchedulerEndpoints,
    ConfigUtils.kafka.filterTimeInSeconds
  )

  val schedulerCommandsConsumerSupervisor = BackoffSupervisor.props(
    Backoff.onStop(
      schedulerCommandsConsumerProps,
      childName = "scheduler-commands-consumer",
      minBackoff = 3.seconds,
      maxBackoff = 30.seconds,
      randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
    ).withSupervisorStrategy(
      OneForOneStrategy() {
        case ex =>
          system.log.error("There was an error in TasksConsumer", ex)
          SupervisorStrategy.Restart //Here we can add some log or send a notification
      })
  )

  system.actorOf(schedulerCommandsConsumerSupervisor)

  val route =
    path("") {
      get {
        // TODO: Try to connect to real KAFKA
        // TODO: Try to authenticate with InfluxDb with real credentials (from env), but don't error if it's down
        complete(HttpEntity(contentType = ContentTypes.`text/html(UTF-8)`, "<h1>OK</h1>"))
      }
    }

  val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", ConfigUtils.pingPort)

  sys.addShutdownHook {
    tasksKafkaConsumer.shutdown()
    schedulerCommandsKafkaConsumer.shutdown()
    Thread.sleep(30.seconds.toMillis)
  }
}