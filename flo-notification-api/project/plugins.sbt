resolvers += Resolver.url("bintray-sbt-plugin-releases", url("http://dl.bintray.com/content/sbt/sbt-plugin-releases"))(
  Resolver.ivyStylePatterns)
resolvers += Classpaths.sbtPluginReleases

addSbtCoursier
addSbtPlugin("ch.epfl.scala"                  % "sbt-scalafix"              % "0.9.4")
addSbtPlugin("com.softwaremill.clippy"        % "plugin-sbt"                % "0.6.1")
addSbtPlugin("com.sksamuel.scapegoat"         %% "sbt-scapegoat"            % "1.0.9")
addSbtPlugin("org.scoverage"                  % "sbt-scoverage"             % "1.5.1")
addSbtPlugin("com.geirsson"                   % "sbt-scalafmt"              % "1.5.1")
addSbtPlugin("org.duhemm"                     % "sbt-errors-summary"        % "0.6.3")
addSbtPlugin("org.scalastyle"                 %% "scalastyle-sbt-plugin"    % "1.0.0")
addSbtPlugin("org.wartremover"                % "sbt-wartremover"           % "2.4.1")

addSbtPlugin("com.swoval"                     %% "sbt-close-watch"          % "2.1.0")
addSbtPlugin("io.spray"                       % "sbt-revolver"              % "0.9.1")