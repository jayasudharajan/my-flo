import sbt.Keys.libraryDependencies
import sbt._

object Dependencies {
  lazy val versions = new {
    val finatra        = "19.4.0"
    val guice          = "4.2.2"
    val logback        = "1.2.3"
    val mockito        = "1.10.19"
    val scalatest      = "3.0.7"
    val junitInterface = "0.11"
    val dockerItScala  = "0.9.8"
    val scalaUri       = "1.4.5"
    val swaggerFinatra = "19.4.0"
    val perfolation    = "1.1.1"
    val monix          = "3.0.0-fbcb270"
    val floScalaSdk    = "3.0.27"
    val quickLens      = "1.4.12"
    val twilio         = "7.44.0"
    val scaffeine      = "3.0.0"
    val circe          = "0.11.1"
  }

  lazy val scalaTest = "org.scalatest" %% "scalatest" % "3.0.5"

  val excludeNetty = ExclusionRule(organization = "io.netty")
  val excludeSlf4j = ExclusionRule(organization = "org.slf4j")

  lazy val libraries = Seq(
    "com.flo"                      %% "flo-notification-sdk"            % "0.4.72-SNAPSHOT"
      excludeAll (excludeNetty, excludeSlf4j),
    "com.flo"                      %% "flo-scala-sdk"                   % versions.floScalaSdk
      excludeAll (excludeNetty, excludeSlf4j),

    "com.twilio.sdk"               %  "twilio"                          % versions.twilio,
    "com.jakehschwartz"            %% "finatra-swagger"                 % versions.swaggerFinatra,
    "com.outr"                     %% "perfolation"                     % versions.perfolation,
    "io.monix"                     %% "monix-execution"                 % versions.monix,
    "io.lemonlabs"                 %% "scala-uri"                       % versions.scalaUri,
    "com.twitter"                  %% "bijection-util"                  % "0.9.6",
    "com.twitter"                  %% "finatra-http"                    % versions.finatra,
    "com.twitter"                  %% "finatra-httpclient"              % versions.finatra,
    "com.twitter"                  %% "finatra-jackson"                 % versions.finatra,
    "ch.qos.logback"               % "logback-classic"                  % versions.logback,
    "com.twitter"                  %% "twitter-server-logback-classic"  % versions.finatra,
    "com.twitter"                  %% "inject-request-scope"            % versions.finatra,
    "io.getquill"                  %% "quill-async-postgres"            % "3.1.0"
      excludeAll (excludeNetty, excludeSlf4j),
    "org.postgresql"                % "postgresql"                      % "9.4.1208",
    "com.github.blemale"           %% "scaffeine"                       % versions.scaffeine,
    "com.softwaremill.quicklens"   %% "quicklens"                       % versions.quickLens,
    "io.kevinlee"                  %% "just-semver"                     % "0.1.0",


    "io.circe" %% "circe-core" % versions.circe,
    "io.circe" %% "circe-generic" % versions.circe,
    "io.circe" %% "circe-parser" % versions.circe,

    "com.twitter"                  %% "finatra-http"                    % versions.finatra % Test,
    "com.twitter"                  %% "finatra-jackson"                 % versions.finatra % Test,
    "com.twitter"                  %% "inject-server"                   % versions.finatra % Test,
    "com.twitter"                  %% "inject-app"                      % versions.finatra % Test,
    "com.twitter"                  %% "inject-core"                     % versions.finatra % Test,
    "com.twitter"                  %% "inject-modules"                  % versions.finatra % Test,
    "com.google.inject.extensions" % "guice-testlib"                    % versions.guice   % Test,
    "com.twitter"                  %% "finatra-http"                    % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "finatra-jackson"                 % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "inject-server"                   % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "inject-app"                      % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "inject-core"                     % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "inject-modules"                  % versions.finatra % Test classifier "tests",
    "com.twitter"                  %% "inject-request-scope"            % versions.finatra % Test classifier "tests",
    "org.mockito"                  % "mockito-core"                     % versions.mockito        % Test,
    "org.scalatest"                %% "scalatest"                       % versions.scalatest      % Test,
    "com.novocode"                 % "junit-interface"                  % versions.junitInterface % Test,
    "com.whisk"                    %% "docker-testkit-scalatest"        % versions.dockerItScala  % Test,
    "com.whisk"                    %% "docker-testkit-impl-docker-java" % versions.dockerItScala  % Test,
    "org.scalamock" %% "scalamock" % "4.1.0" % Test,
    "com.danielasfregola" %% "random-data-generator" % "2.6" % Test
  )
}
