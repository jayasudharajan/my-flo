package com.flo.puck.http.gateway

sealed trait ValveState
case object Close             extends ValveState
case object Open              extends ValveState
case object UnknownValveState extends ValveState

case class Valve(
  lastKnown: Option[ValveState],
  target: Option[ValveState]
)