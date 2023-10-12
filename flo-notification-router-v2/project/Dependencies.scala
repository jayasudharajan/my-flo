import sbt._

object Dependencies {
  object Versions {
    val Akka = "2.6.1"
    val AkkaHttp = "10.1.11"
    val AkkaStreamKafka = "1.1.0"
    val AwsSdk = "1.11.586"
    val Cats = "1.6.1"
    val Circe = "0.12.1"
    val LogbackClassic = "1.2.3"
    val FloScalaSdk = "3.0.38"
    val FloNotificationSdk = "0.4.69-SNAPSHOT"
    val Json4s = "3.6.7"
    val Kamon = "0.6.7"
    val Mockito = "1.5.17"
    val Perfolation = "1.1.1"
    val PureConfig = "0.11.1"
    val QuickLens = "1.4.12"
    val Redis = "1.9.0-flo-jvm8"
    val Scaffeine = "3.0.0"
    val ScalaLogging = "3.9.2"
    val ScalaTest = "3.0.8"
    val Sealerate = "0.0.5"
  }

  lazy val libraries: Seq[ModuleID] = Seq(
    "com.typesafe.akka"          %% "akka-actor"              % Versions.Akka,
    "com.typesafe.akka"          %% "akka-http"               % Versions.AkkaHttp,
    "com.typesafe.akka"          %% "akka-stream"             % Versions.Akka,
    "com.typesafe.akka"          %% "akka-stream-kafka"       % Versions.AkkaStreamKafka,
    "com.amazonaws"               % "aws-java-sdk-sns"        % Versions.AwsSdk,
    "org.typelevel"              %% "cats-core"               % Versions.Cats,
    "io.circe"                   %% "circe-core"              % Versions.Circe,
    "io.circe"                   %% "circe-generic-extras"    % Versions.Circe,
    "io.circe"                   %% "circe-generic"           % Versions.Circe,
    "org.json4s"                 %% "json4s-core"             % Versions.Json4s,
    "org.json4s"                 %% "json4s-native"           % Versions.Json4s,
    "org.json4s"                 %% "json4s-ext"              % Versions.Json4s,
    "io.kamon"                   %% "kamon-core"              % Versions.Kamon,
    "ch.qos.logback"              % "logback-classic"         % Versions.LogbackClassic,
    "com.flo"                    %% "flo-notification-sdk"    % Versions.FloNotificationSdk,
    "com.flo"                    %% "flo-scala-sdk"           % Versions.FloScalaSdk,
    "com.outr"                   %% "perfolation"             % Versions.Perfolation,
    "com.github.pureconfig"      %% "pureconfig"              % Versions.PureConfig,
    "com.softwaremill.quicklens" %% "quicklens"               % Versions.QuickLens,
    "com.github.etaty"           %% "rediscala"               % Versions.Redis,
    "com.github.blemale"         %% "scaffeine"               % Versions.Scaffeine,
    "com.typesafe.scala-logging" %% "scala-logging"           % Versions.ScalaLogging,
    "ca.mrvisser"                %% "sealerate"               % Versions.Sealerate,

    "org.scalatest"              %% "scalatest"               % Versions.ScalaTest % Test,
    "org.mockito"                %% "mockito-scala"           % Versions.Mockito   % Test
  )
}
