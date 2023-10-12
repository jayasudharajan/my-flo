package flo.modules

import com.google.inject.Provides
import com.jakehschwartz.finatra.swagger.SwaggerModule
import io.swagger.models.{Contact, Info, Swagger}
import io.swagger.models.auth.BasicAuthDefinition

object ServiceSwaggerModule extends SwaggerModule {
  val swaggerUI      = new Swagger()
  val serviceVersion = flag[String]("service.version", "1.0.0", "the version of service")

  @Provides
  def swagger: Swagger = {

    val info = new Info()
      .contact(new Contact().name("Facundo Rossi").email("facundo@flotechnologies.com"))
      .description("**Notification APIi** - API to handle things related to notification system.")
      .version(serviceVersion())
      .title("Notification API")

    swaggerUI
      .info(info)
      .addSecurityDefinition("sampleBasic", {
        val d = new BasicAuthDefinition()
        d.setType("basic")
        d
      })

    swaggerUI
  }
}
