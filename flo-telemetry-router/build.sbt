import sbt.Resolver

name := "flo-telemetry-router"

version := "1.0"

scalaVersion := "2.11.8"

coverageMinimum := 30

coverageFailOnMinimum := true

coverageHighlighting := false

scalacOptions ++= Seq(
	"-deprecation",
	"-encoding", "UTF-8",
	"-feature",
	"-language:existentials",
	"-language:higherKinds",
	"-language:implicitConversions",
	"-language:reflectiveCalls",
	"-unchecked",
	//"-Xfatal-warnings",
	"-Xlint",
	"-Yno-adapted-args",
	"-Ywarn-dead-code",
	//"-Ywarn-value-discard",
	"-Xfuture",
	//"-Ywarn-unused-import", // 2.11 only
	//"-Yno-predef", // no automatic import of Predef (removes irritating implicits)
	"-Xmax-classfile-name","240" // So docker container build will work
)

lazy val akkaVersion = "2.5.14"

lazy val akkaHttpVersion = "10.1.3"

lazy val json4sVersion = "3.5.0"

lazy val kamonVersion = "0.6.3"


libraryDependencies ++= Seq(
	// Flo Libraries
	"com.flo" %% "flo-scala-sdk" % "2.8.5",
	"com.flo" %% "flo-scala-encryption" % "1.1.4",
	"com.flo" %% "flo-scala-communication" % "3.0.5",

	// Lens library
	"com.softwaremill.quicklens" %% "quicklens" % "1.4.8",

	// Typesafe config
	"com.typesafe" % "config" % "1.3.1",

	// Joda Time
	"joda-time" % "joda-time" % "2.9.7",
	"org.joda" % "joda-convert" % "1.8.1",

	// Logging
	"ch.qos.logback" % "logback-classic" % "1.2.1",
	"com.typesafe.scala-logging" %% "scala-logging" % "3.5.0",

	// Influx DB
	"org.influxdb" % "influxdb-java" % "2.10",

	// Akka
	"com.typesafe.akka" %% "akka-actor" % akkaVersion,
	"com.typesafe.akka" %% "akka-testkit" % akkaVersion,
	"com.typesafe.akka" %% "akka-slf4j" % akkaVersion,
	"com.typesafe.akka" %% "akka-contrib" % akkaVersion,
	"com.typesafe.akka" %% "akka-stream" % akkaVersion,

	// Akka Kafka Stream
	"com.typesafe.akka" %% "akka-stream-kafka" % "0.22",

	// Akka Http
	"com.typesafe.akka" %% "akka-http" % akkaHttpVersion,

	// Monitoring
	"io.kamon" %% "kamon-core" % kamonVersion,
	"io.kamon" %% "kamon-statsd" % kamonVersion,
	"io.kamon" %% "kamon-system-metrics" % kamonVersion,
	"io.kamon" %% "kamon-scala" % kamonVersion,
	"io.kamon" %% "kamon-akka" % kamonVersion,
	"io.kamon" %% "kamon-autoweave" % kamonVersion,

	// Test
	"org.scalamock" %% "scalamock" % "4.1.0" % Test,
	"org.scalatest" %% "scalatest" % "3.0.4" % "test"
)

resolvers ++= Seq(
	"Flo Realm" at "https://flo.bintray.com/maven",
	"Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots",
	"Sonatype OSS Releases" at "https://oss.sonatype.org/content/repositories/releases",
	"Confluent" at "http://packages.confluent.io/maven/",
	Resolver.bintrayRepo("ovotech", "maven")
)

// Bring the sbt-aspectj settings into this build
enablePlugins(SbtAspectj)

// Here we are effectively adding the `-javaagent` JVM startup
// option with the location of the AspectJ Weaver provided by
// the sbt-aspectj plugin.
javaOptions in run ++= (aspectjWeaverOptions in Aspectj).value

// We need to ensure that the JVM is forked for the
// AspectJ Weaver to kick in properly and do it's magic.
fork in run := true

assemblyJarName := "app.jar"
mainClass in assembly := Some("com.flo.router.telemetry.TelemetryRouterApplication")

assemblyMergeStrategy in assembly := {
	case PathList("reference.conf") => MergeStrategy.concat
	case "application.conf"  => MergeStrategy.concat
	case PathList("javax", "servlet", xs@_*) => MergeStrategy.first
	case PathList(ps@_*) if ps.last endsWith ".html" => MergeStrategy.first
	//START: Solve the problem of invalid signature
	case PathList("META-INF", "BCKEY.DSA") => MergeStrategy.discard
	case PathList("META-INF", "BCKEY.SF") => MergeStrategy.discard
	//END: Solve the problem of invalid signature
	case PathList("META-INF", "MANIFEST.MF") => MergeStrategy.discard
	case n if n.startsWith("reference.conf") => MergeStrategy.concat
	case n if n.endsWith(".conf") => MergeStrategy.concat
	case x => MergeStrategy.first
}
