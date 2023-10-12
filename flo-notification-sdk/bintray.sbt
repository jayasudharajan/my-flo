import sbt.Credentials
import sbt.Keys.credentials

publishTo := Some("bintray" at "https://api.bintray.com/maven/flo/maven/flo-notification-sdk")


val bintrayConfig = for {
  user <- sys.env.get("BINTRAY_USER")
  key <- sys.env.get("BINTRAY_KEY")
} yield (user, key)


bintrayConfig.toSeq map ( config => {
  //For retrieve dependencies
  credentials += Credentials(
    "Bintray",
    "flo.bintray.com",
    config._1,
    config._2
  )


  // For publish the library
  credentials += Credentials(
    "Bintray API Realm",
    "api.bintray.com",
    config._1,
    config._2
  )
 
})
