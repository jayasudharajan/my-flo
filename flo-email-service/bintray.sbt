val bintrayConfig = for {
	user <- sys.env.get("BINTRAY_USER")
	key <- sys.env.get("BINTRAY_KEY")
} yield (user, key)


bintrayConfig.toSeq map ( config =>
	credentials += Credentials(
		"Bintray",
		"flo.bintray.com",
		config._1,
		config._2
	))