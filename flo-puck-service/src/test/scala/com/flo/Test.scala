package com.flo

import com.flo.util.RandomDataGeneratorUtil
import org.scalatest.{EitherValues, Matchers, OptionValues}
import org.scalatest.concurrent.{Eventually, ScalaFutures}
import org.scalatestplus.mockito.MockitoSugar

trait Test
  extends OptionValues
  with EitherValues
  with Matchers
  with ScalaFutures
  with Eventually
  with MockitoSugar
  with RandomDataGeneratorUtil
