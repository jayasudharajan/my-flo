package com.flo

import org.scalatest.concurrent.{Eventually, ScalaFutures}
import org.scalatest.{Matchers, OptionValues}
import org.scalatestplus.mockito.MockitoSugar

trait Test
    extends OptionValues
    with Matchers
    with ScalaFutures
    with Eventually
    with MockitoSugar