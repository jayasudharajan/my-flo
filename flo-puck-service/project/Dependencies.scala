import sbt._

object Dependencies {
  object Versions {
    val AkkaHttp = "10.1.11"
    val AkkaHttpCirce = "1.30.0"
    val AkkaStreamKafka = "1.1.0"
    val Circe = "0.12.1"
    val HikariCp = "3.4.2"
    val LogbackClassic = "1.2.3"
    val Mockito = "1.5.17"
    val Perfolation = "1.1.5"
    val Postgresql = "42.2.9"
    val PureConfig = "0.11.0"
    val QuickLens = "1.4.12"
    val ScalaLogging = "3.9.2"
    val ScalaTest = "3.0.8"
    val RandomDataGenerator = "2.6"
  }

  lazy val libraries: Seq[ModuleID] = Seq(
    "de.heikoseeberger"          %% "akka-http-circe"       % Versions.AkkaHttpCirce,
    "com.typesafe.akka"          %% "akka-stream-kafka"     % Versions.AkkaStreamKafka,
    "io.circe"                   %% "circe-core"            % Versions.Circe,
    "io.circe"                   %% "circe-generic-extras"  % Versions.Circe,
    "io.circe"                   %% "circe-generic"         % Versions.Circe,
    "io.circe"                   %% "circe-parser"          % Versions.Circe,
    "com.zaxxer"                  % "HikariCP"              % Versions.HikariCp,
    "ch.qos.logback"              % "logback-classic"       % Versions.LogbackClassic,
    "com.outr"                   %% "perfolation"           % Versions.Perfolation,
    "org.postgresql"              % "postgresql"            % Versions.Postgresql,
    "com.github.pureconfig"      %% "pureconfig"            % Versions.PureConfig,
    "com.softwaremill.quicklens" %% "quicklens"             % Versions.QuickLens,
    "com.typesafe.scala-logging" %% "scala-logging"         % Versions.ScalaLogging,
    "com.typesafe.akka"          %% "akka-http"             % Versions.AkkaHttp,

    "org.scalatest"              %% "scalatest"             % Versions.ScalaTest % Test,
    "org.mockito"                %% "mockito-scala"         % Versions.Mockito   % Test,
    "com.danielasfregola"        %% "random-data-generator" % Versions.RandomDataGenerator % Test
  )
}
