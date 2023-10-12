logLevel := Level.Warn

resolvers += Classpaths.sbtPluginReleases

resolvers += "Flyway" at "https://flywaydb.org/repo"

addSbtPlugin("io.github.davidmweber" % "flyway-sbt" % "5.2.0")
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "1.1.0")