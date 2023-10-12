import sbt.Resolver

name := "flo-scala-communication"

version := "3.1.3"

organization := "com.flo"

scalaVersion := "2.12.9"

crossScalaVersions := Seq("2.11.8", "2.12.9")

//  See: http://www.scala-lang.org/files/archive/nightly/docs/manual/html/scalac.html
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

lazy val kafkaVersion = "2.1.0"

lazy val akkaVersion = "2.5.18"

lazy val akkaHttpVersion = "10.1.5"

lazy val json4sVersion = "3.5.0"

lazy val kamonVersion = "0.6.7"

val dependencies = Seq(
  //Logging
  "com.typesafe.scala-logging" %% "scala-logging" % "3.5.0",
  "log4j" % "log4j" % "1.2.17",

  // Joda Time
  "joda-time" % "joda-time" % "2.9.9",

  //Json
  "org.json4s" %% "json4s-core" % json4sVersion,
  "org.json4s" %% "json4s-native" % json4sVersion,
  "org.json4s" %% "json4s-ext" % json4sVersion,

  // Akka
  "com.typesafe.akka" %% "akka-actor" % akkaVersion,
  "com.typesafe.akka" %% "akka-testkit" % akkaVersion,
  "com.typesafe.akka" %% "akka-slf4j" % akkaVersion,
  "com.typesafe.akka" %% "akka-contrib" % akkaVersion,
  "com.typesafe.akka" %% "akka-stream" % akkaVersion,

  // Akka Kafka Stream
  "com.typesafe.akka" %% "akka-stream-kafka" % "1.0.3",

  // Serialization
  "com.sksamuel.avro4s" %% "avro4s-core" % "2.0.2",
  "io.confluent" % "kafka-avro-serializer" % "5.0.1",
  "com.ovoenergy" %% "kafka-serialization-avro4s" % "0.3.19",

  // Monitoring
  "io.kamon" %% "kamon-core" % kamonVersion,

  //Kafka
  "org.apache.kafka" % "kafka-clients" % kafkaVersion,
  "org.apache.kafka" % "kafka-clients" % kafkaVersion classifier("test"),

  //Kafka Test Utils
  "io.github.embeddedkafka" %% "embedded-kafka" % "2.2.0" % "test",

  //Test
  "org.scalatest" %% "scalatest" % "3.0.2" % "test"
)

libraryDependencies ++= dependencies


externalResolvers := Seq(
  "Nexus Maven Central Mirror" at "https://nexus.flotech.co/repository/maven-central",
  "Ovotech Mirror" at "https://nexus.flotech.co/repository/maven-ovotech/",
  "Confluent Mirror" at "https://nexus.flotech.co/repository/maven-confluent/"
)

parallelExecution in Test := false

credentials += Credentials("Sonatype Nexus Repository Manager", "nexus.flotech.co",  sys.env.get("NEXUS_USER").orNull, sys.env.get("NEXUS_PASSWORD").orNull)
