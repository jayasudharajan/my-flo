package flo.modules

import com.google.inject.assistedinject.FactoryModuleBuilder
import com.twitter.inject.TwitterModule
import com.twitter.inject.requestscope.RequestScopeBinding
import flo.services.{DefaultGatewayService, GatewayService, GatewayServiceFactory}

object TokenModule extends TwitterModule with RequestScopeBinding {

  override def configure(): Unit = {
    super.configure()

    bindRequestScope[GatewayService]

    install(
      new FactoryModuleBuilder()
        .implement(classOf[GatewayService], classOf[DefaultGatewayService])
        .build(classOf[GatewayServiceFactory])
    )
  }
}
