import sbt._

object Dependencies {
  object Versions {
    val AkkaStreamKafka = "1.1.0"
    val Circe = "0.12.1"
    val FloScalaSdk = "3.0.23"
    val LogbackClassic = "1.2.3"
    val Mockito = "1.5.17"
    val Perfolation = "1.1.5"
    val PureConfig = "0.11.0"
    val QuickLens = "1.4.12"
    val ScalaLogging = "3.9.2"
    val ScalaTest = "3.0.8"
  }

  lazy val libraries: Seq[ModuleID] = Seq(
    "com.typesafe.akka"          %% "akka-stream-kafka"     % Versions.AkkaStreamKafka,
    "io.circe"                   %% "circe-core"            % Versions.Circe,
    "io.circe"                   %% "circe-generic-extras"  % Versions.Circe,
    "io.circe"                   %% "circe-generic"         % Versions.Circe,
    "io.circe"                   %% "circe-parser"          % Versions.Circe,
    "com.flo"                    %% "flo-scala-sdk"         % Versions.FloScalaSdk,
    "ch.qos.logback"              % "logback-classic"       % Versions.LogbackClassic,
    "com.outr"                   %% "perfolation"           % Versions.Perfolation,
    "com.github.pureconfig"      %% "pureconfig"            % Versions.PureConfig,
    "com.softwaremill.quicklens" %% "quicklens"             % Versions.QuickLens,
    "com.typesafe.scala-logging" %% "scala-logging"         % Versions.ScalaLogging,

    "org.scalatest"              %% "scalatest"             % Versions.ScalaTest % Test,
    "org.mockito"                %% "mockito-scala"         % Versions.Mockito   % Test
  )
}

