logLevel := Level.Warn

// SBT Assembly (Produces FAT Jar)
// sbt assembly
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.14.5")

// Scalastyle examines your Scala code and indicates potential problems with it.
// sbt scalastyle
addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "1.0.0")

addSbtPlugin("com.lightbend.sbt" % "sbt-aspectj" % "0.11.0")

addSbtPlugin("org.scoverage" % "sbt-scoverage" % "1.5.1")