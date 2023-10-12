package com.flo.notification.sdk

import com.opentable.db.postgres.embedded.EmbeddedPostgres
import org.flywaydb.core.Flyway
import org.slf4j.LoggerFactory

class DatabaseTestService(postgresPort: Int, flywayMigrationsLocation: String) {
  private val logger = LoggerFactory.getLogger(classOf[DatabaseTestService])

  var pg: EmbeddedPostgres = _

  val user = "postgres"
  val password = "postgres"
  val databaseName = "postgres"

  def start() = {
    pg = EmbeddedPostgres.builder().setPort(postgresPort).start()
    logger.info(s"EmbeddedPostgres started at port ${pg.getPort}")

    val flyway = Flyway
      .configure
      .locations(flywayMigrationsLocation)
      .dataSource(pg.getJdbcUrl(user, databaseName), user, password)
      .load

    flyway.migrate
  }

  def stop() = {
    pg.close()
    logger.info("EmbeddedPostgres stopped")
  }
}