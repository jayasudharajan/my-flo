
name := "flo-notification-sdk"

version := "0.4.72-SNAPSHOT"

organization := "com.flo"

scalaVersion := "2.12.11"

scalacOptions ++= Seq(
  "-deprecation",
  "-feature",
  "-encoding", "UTF-8",
  "-language:existentials",
  "-language:higherKinds",
  "-language:implicitConversions",
  "-unchecked",
  "-Xlint",
  "-Yno-adapted-args",
  "-Ywarn-dead-code",
  "-Ywarn-numeric-widen",
  "-Ywarn-unused-import"
)

lazy val kamonVersion = "0.6.7"
lazy val circeVersion = "0.11.1"
lazy val json4sVersion = "3.6.0"
lazy val rediscalaVersion = "1.9.0-flo-jvm8"

val dependencies = Seq(
  // Flo libraries
  "com.flo" %% "flo-scala-communication" % "3.1.3",
  "com.flo" %% "flo-scala-sdk" % "3.0.38",

  // Logging
  "com.typesafe.scala-logging" %% "scala-logging" % "3.5.0",
  //"log4j" % "log4j" % "1.2.17",

  // Joda Time
  "joda-time" % "joda-time" % "2.9.9",

  // Monitoring
  "io.kamon" %% "kamon-core" % kamonVersion,

  // JDBC
  //"io.getquill" %% "quill-async-postgres" % "3.4.4",
  "io.getquill" %% "quill-jdbc" % "3.4.4",
  "org.postgresql" % "postgresql" % "42.2.6",

  "org.flywaydb" % "flyway-core" % "5.2.0",

  // Json4s
  "org.json4s" %% "json4s-jackson" % json4sVersion,

  // Redis
  "com.github.etaty" %% "rediscala" % rediscalaVersion,

  "com.github.blemale"  %% "scaffeine" % "3.0.0",

  "com.outr" %% "perfolation" % "1.1.1",
  "com.softwaremill.quicklens" %% "quicklens" % "1.4.12",

  // Test
  "org.scalamock" %% "scalamock" % "4.1.0" % Test,
  "org.scalatest" %% "scalatest" % "3.0.4" % "test",
  "com.opentable.components" % "otj-pg-embedded" % "0.13.1",
  "com.danielasfregola" %% "random-data-generator" % "2.6"
)

libraryDependencies ++= dependencies
externalResolvers := Seq(
	"Nexus Maven Central Mirror" at "https://nexus.flotech.co/repository/maven-all"
)

assemblyMergeStrategy in assembly := {
  case x if x.contains("io/netty") => MergeStrategy.first
  case x if x.contains("io.netty.versions.properties") => MergeStrategy.first
  case x if x.contains("org/apache/commons/logging") => MergeStrategy.first
  case x if x.contains("org/slf4j/impl") => MergeStrategy.last
  case "LogFilter.class" => MergeStrategy.first
  case x =>
    val oldStrategy = (assemblyMergeStrategy in assembly).value
    oldStrategy(x)
}


//resolvers ++= Seq(
//  "Flo Realm" at "https://flo.bintray.com/maven",
//  Resolver.sonatypeRepo("releases"),
//  Resolver.sonatypeRepo("snapshots"),
//  "Confluent" at "http://packages.confluent.io/maven/",
//  Resolver.bintrayRepo("ovotech", "maven")
//)

flywayLocations := Seq("db/migration")

flywayBaselineOnMigrate := true

enablePlugins(FlywayPlugin)
credentials += Credentials("Sonatype Nexus Repository Manager", "nexus.flotech.co",  sys.env.get("NEXUS_USER").orNull, sys.env.get("NEXUS_PASSWORD").orNull)
parallelExecution in Test := true
