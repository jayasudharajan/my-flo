package com.flo.notification.sdk

import com.typesafe.config.{ConfigFactory, ConfigValueFactory}
import org.scalatest.{FutureOutcome, fixture}
import com.typesafe.config.Config

trait DbFixture { this: fixture.AsyncTestSuite =>

  type FixtureParam = Config

  def withFixture(test: OneArgAsyncTest): FutureOutcome = {
    val start = 9200
    val end   = 9999
    val random = new scala.util.Random
    val port = start + random.nextInt((end - start) + 1)

    val newConfig = ConfigFactory
      .load
      .withValue(
        "ctx.url",
        ConfigValueFactory.fromAnyRef(s"postgresql://localhost:$port/postgres?user=postgres&password=postgres")
      )
      .withValue("ctx.sslmode", ConfigValueFactory.fromAnyRef("disable"))
      .withValue("ctx.charset", ConfigValueFactory.fromAnyRef("UTF-8"))
      .withValue("ctx.connectTimeout", ConfigValueFactory.fromAnyRef("5s"))
      .withValue("ctx.testTimeout", ConfigValueFactory.fromAnyRef("5s"))
      .withValue("ctx.queryTimeout", ConfigValueFactory.fromAnyRef("5s"))

    val dbTestService = new DatabaseTestService(port, "db/migration/schema")

    dbTestService.start()

    val dataBaseConfig = newConfig.getConfig("ctx")

    complete {
      withFixture(test.toNoArgAsyncTest(dataBaseConfig))
    } lastly {
      dbTestService.stop()
    }
  }
}