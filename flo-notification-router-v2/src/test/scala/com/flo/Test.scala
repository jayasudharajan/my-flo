package com.flo

import com.flo.notification.router.core.api.RandomFixtures
import org.scalatest.concurrent.{Eventually, ScalaFutures}
import org.scalatest.{Matchers, OptionValues}
import org.scalatestplus.mockito.MockitoSugar

trait Test extends OptionValues with Matchers with ScalaFutures with Eventually with MockitoSugar with RandomFixtures
