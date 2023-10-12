package flo.filters

import com.twitter.finagle.http.Request
import com.twitter.finatra.filters.MergedFilter
import com.twitter.finatra.http.filters._
import javax.inject.{Inject, Singleton}

@Singleton
class CommonFilters @Inject()(
    a: StatsFilter[Request],
    c: HttpResponseFilter[Request],
    d: ExceptionMappingFilter[Request],
    e: HttpNackFilter[Request]
) extends MergedFilter(a, c, d, e)
