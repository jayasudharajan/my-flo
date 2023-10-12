package flo.modules

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.google.inject.Provides
import com.twitter.inject.TwitterModule
import javax.inject.Singleton

import scala.concurrent.ExecutionContext

object AkkaModule extends TwitterModule {
  private val actorSystem: ActorSystem             = ActorSystem("flo-notification-api-v2")
  private val actorMaterializer: ActorMaterializer = ActorMaterializer()(actorSystem)

  @Singleton
  @Provides
  def provideActorSystem: ActorSystem = actorSystem

  @Singleton
  @Provides
  def provideActorMaterializer: ActorMaterializer = actorMaterializer

  @Singleton
  @Provides
  def provideExecutionContext: ExecutionContext = actorSystem.dispatcher
}
