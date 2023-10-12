package com.flo.notification.sdk.service

import com.flo.notification.sdk.model.Filter
import org.scalatest.{Matchers, WordSpec}

class FilterSpec extends WordSpec with Matchers {

  "Filter" should {
    "generateLocalDateTimeFilters from a list of Strings" in {
      val date = "2011-12-03T10:15:30"
      val operator = "eq"

      val filters = Filter
        .generateLocalDateTimeFilters(List(s"${operator}:${date}Z", date))

      filters.foreach(x => {
        x.value.toString shouldEqual date
        x.operator shouldEqual operator
      })
    }
  }
}
