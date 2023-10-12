import Dependencies._
import sbt.Keys.libraryDependencies

scalaVersion     := "2.12.11"
version          := "0.1.0-SNAPSHOT"
organization     := "com.flo"
organizationName := "flo"

name := "flo-notification-api"

addCompilerPlugin("com.olegpy"       %% "better-monadic-for" % "0.3.0")
addCompilerPlugin("com.github.cb372" %% "scala-typed-holes"  % "0.0.3")

fork in run := true

libraryDependencies ++= libraries

//To fix an issue on Java 10
libraryDependencies += "com.sun.activation" % "javax.activation" % "1.2.0"
libraryDependencies += "javax.xml.bind" % "jaxb-api" % "2.3.0"

resolvers ++= Seq(
  "Confluent" at "http://packages.confluent.io/maven/"
)
resolvers ++= Seq( 
	"Flo Nexus" at "https://nexus.flotech.co/repository/maven-releases",
    "Flo Nexus Public" at "https://nexus.flotech.co/repository/maven-all"
)

mainClass in reStart := Some("flo.ServerMain")

coverageMinimum := 70
coverageFailOnMinimum := true
coverageExcludedPackages := ".*util*."

scalafmtConfig := Some(file(".scalafmt.conf"))
scalafmtOnCompile := true

autoCompilerPlugins := true

//Scape static analysis tool config, see https://github.com/sksamuel/scapegoat
scapegoatVersion in ThisBuild := "1.3.8"

testOptions += Tests.Argument(TestFrameworks.JUnit, "-q", "-v")

parallelExecution in Test := false

fork in Test := false

clippyColorsEnabled := true

scalacOptions ++= Seq(
  "-target:jvm-1.8",
  "-encoding",
  "UTF-8",
  "-unchecked",
  "-language:existentials",
  "-language:experimental.macros",
  "-language:higherKinds",
  "-language:implicitConversions",
  "-deprecation",
  "-explaintypes",
  "-feature",
  "-Xcheckinit",
  "-Xlint:adapted-args", // Warn if an argument list is modified to match the receiver.
  "-Xlint:by-name-right-associative", // By-name parameter of right associative operator.
  "-Xlint:constant", // Evaluation of a constant arithmetic expression results in an error.
  "-Xlint:delayedinit-select", // Selecting member of DelayedInit.
  "-Xlint:doc-detached", // A Scaladoc comment appears to be detached from its element.
  "-Xlint:inaccessible", // Warn about inaccessible types in method signatures.
  "-Xlint:infer-any", // Warn when a type argument is inferred to be `Any`.
  "-Xlint:missing-interpolator", // A string literal appears to be missing an interpolator id.
  "-Xlint:nullary-override", // Warn when non-nullary `def f()' overrides nullary `def f'.
  "-Xlint:nullary-unit", // Warn when nullary methods return Unit.
  "-Xlint:option-implicit", // Option.apply used implicit view.
  // "-Xlint:package-object-classes", // Class or object defined in package object.
  "-Xlint:poly-implicit-overload", // Parameterized overloaded implicit methods are not visible as view bounds.
  "-Xlint:private-shadow", // A private field (or class parameter) shadows a superclass field.
  "-Xlint:stars-align", // Pattern sequence wildcard must align with sequence component.
  "-Xlint:type-parameter-shadow", // A local type parameter shadows a type already in scope.
  "-Xlint:unsound-match", // Pattern match may not be typesafe.
  "-Yno-adapted-args", // Do not adapt an argument list (either by inserting () or creating a tuple) to match the receiver.
  "-Ypartial-unification", // Enable partial unification in type constructor inference
  "-Yrangepos",
  "-Ywarn-dead-code", // Warn when dead code is identified.
  "-Ywarn-extra-implicit", // Warn when more than one implicit parameter section is defined.
  "-Ywarn-inaccessible", // Warn about inaccessible types in method signatures.
  "-Ywarn-infer-any", // Warn when a type argument is inferred to be `Any`.
  "-Ywarn-nullary-override", // Warn when non-nullary `def f()' overrides nullary `def f'.
  "-Ywarn-nullary-unit", // Warn when nullary methods return Unit.
  "-Ywarn-numeric-widen", // Warn when numerics are widened.
  "-Ywarn-unused:implicits", // Warn if an implicit parameter is unused.
  "-Ywarn-unused:imports", // Warn if an import selector is not referenced.
  "-Ywarn-unused:locals", // Warn if a local definition is unused.
  "-Ywarn-unused:params", // Warn if a value parameter is unused.
  "-Ywarn-unused:patvars", // Warn if a variable bound in a pattern is unused.
  "-Ywarn-unused:privates", // Warn if a private member is unused.
  "-Ywarn-value-discard", // Warn when non-Unit expression results are unused.
  "-P:clippy:colors=true",
  "-Ycache-plugin-class-loader:last-modified",
  "-Ycache-macro-class-loader:last-modified",
  "-Ybackend-parallelism",
  s"${sys.runtime.availableProcessors() * 2}",
  "-Ybackend-worker-queue",
  "8",
  "-P:bm4:no-filtering:y",
  "-P:bm4:no-map-id:y",
  "-P:bm4:no-tupling:y",
  "-P:bm4:implicit-patterns:y",
)

// No need to run tests while building jar
//test in assembly := {}
assemblyJarName := "app-assembly.jar"
mainClass in assembly := Some("flo.ServerMain")

assemblyMergeStrategy in assembly := {
  case PathList("javax", "servlet", xs@_*) => MergeStrategy.first
  case PathList(ps@_*) if ps.last endsWith ".html" => MergeStrategy.first
  //START: Solve the problem of invalid signature
  case PathList("META-INF", xs @ _*) =>
    (xs map {_.toLowerCase}) match {
      case ("manifest.mf" :: Nil) =>
        MergeStrategy.discard
      case ps @ (x :: xs) if ps.last.endsWith(".sf") || ps.last.endsWith(".dsa") || ps.last.endsWith(".rsa") =>
        MergeStrategy.discard
      case x => MergeStrategy.first
    }
  //END: Solve the problem of invalid signature
  case n if n.startsWith("reference.conf") => MergeStrategy.concat
  case n if n.endsWith(".conf") => MergeStrategy.concat
  case x => MergeStrategy.first
}
