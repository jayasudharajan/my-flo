package com.flo.puck.core.api

sealed trait Interval

case object Hourly extends Interval
case object Daily extends Interval
case object Monthly extends Interval
