package com.flo.puck.sql

import java.util.Properties

import com.flo.puck.core.api.{HistoricalPuckTelemetryAppender, PuckTelemetryReportRetriever}
import com.typesafe.config.Config
import com.zaxxer.hikari.{HikariConfig, HikariDataSource}

import scala.collection.JavaConverters._
import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def appConfig: Config
  def blockableExecutionContext: ExecutionContext

  // Private
  private def toProperties(config: Config): Properties = {
    val props = new Properties()
    config.entrySet().asScala.foreach(entry => props.put(entry.getKey, entry.getValue.unwrapped().toString))
    props
  }

  private val dbConfig = appConfig.getConfig("database")
  private val connectionPoolConfig = new HikariConfig(toProperties(dbConfig))
  private val pooledDataSource = new HikariDataSource(connectionPoolConfig)
  private val puckTelemetryRepository = new PuckTelemetryRepository(pooledDataSource)(blockableExecutionContext)

  // Provides
  val appendHistoricalPuckTelemetry: HistoricalPuckTelemetryAppender = puckTelemetryRepository.appendPuckTelemetry
  val retrievePuckTelemetryReport: PuckTelemetryReportRetriever = puckTelemetryRepository.retrievePuckTelemetry
}
