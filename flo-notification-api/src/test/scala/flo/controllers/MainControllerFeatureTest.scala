package com.example.finatraexample.controllers

/*
import com.twitter.finagle.http.Status._
import com.twitter.finatra.http.EmbeddedHttpServer
import com.twitter.inject.server.FeatureTest
import flo.Application

class MainControllerFeatureTest extends FeatureTest {
  val serviceVersion: String = "0.9.9"

  override val server: EmbeddedHttpServer =
    new EmbeddedHttpServer(twitterServer = new Application, flags = Map("service.version" -> serviceVersion))

  test("Server should respond") {
    server.httpGet(path = "/greeting/Richard", andExpect = Ok, withJsonBody = """{"message":"Hello, Richard"}""")
    server.httpGet(path = "/greeting/anonymous", andExpect = Ok, withJsonBody = """{"message":"Your name, please?"}""")
    server.httpGet(path = "/greeting/unknown", andExpect = BadRequest)
  }
}
 */
