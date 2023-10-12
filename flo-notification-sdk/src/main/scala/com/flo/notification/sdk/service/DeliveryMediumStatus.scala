package com.flo.notification.sdk.service

object DeliveryMediumStatus {
  val Queued = 1
  val Triggered = 2
  val Received = 3
  val Delivered = 4
  val Open = 5
  val Dropped = 6
  val Bounce = 7
  val Failed = 8
  val Undelivered = 9
  val Ringing = 10
  val InProgress = 11
  val Completed = 12
  val Busy = 13
  val NoAnswer = 14
  val Sent = 15

  private val QueuedStr = "queued"
  private val TriggeredStr = "triggered"
  private val ReceivedStr = "received"
  private val DeliveredStr = "delivered"
  private val FailedStr = "failed"
  private val UndeliveredStr = "Undelivered"
  private val OpenStr = "open"
  private val DroppedStr = "dropped"
  private val BounceStr = "bounce"
  private val RingingStr = "ringing"
  private val InProgressStr = "in-progress"
  private val CompletedStr = "completed"
  private val BusyStr = "busy"
  private val NoAnswerStr = "no-answer"
  private val UnknownStr = "unknown"
  private val SentStr = "sent"

  def toString(deliveryMediumStatus: Int): String =  deliveryMediumStatus match {
    case Queued => QueuedStr
    case Triggered => TriggeredStr
    case Received => ReceivedStr
    case Delivered => DeliveredStr
    case Open => OpenStr
    case Dropped => DroppedStr
    case Bounce => BounceStr
    case Failed => FailedStr
    case Undelivered => UndeliveredStr
    case Ringing => RingingStr
    case InProgress => InProgressStr
    case Completed => CompletedStr
    case Busy => BusyStr
    case NoAnswer => NoAnswerStr
    case Sent => SentStr
    case _ => UnknownStr
  }

  def fromString(deliveryMediumStatus: String): Int = deliveryMediumStatus match {
    case QueuedStr => Queued
    case TriggeredStr => Triggered
    case ReceivedStr => Received
    case DeliveredStr => Delivered
    case OpenStr => Open
    case DroppedStr => Dropped
    case BounceStr => Bounce
    case FailedStr => Failed
    case UndeliveredStr => Undelivered
    case RingingStr => Ringing
    case InProgressStr => InProgress
    case CompletedStr => Completed
    case BusyStr => Busy
    case NoAnswerStr => NoAnswer
    case SentStr => Sent
    case _ => -1
  }

  def fromSendGridEmailEvent(sengridEmailEvent: String): Option[Int] = sengridEmailEvent match {
    case "processed" => Some(Triggered)
    case "dropped" => Some(Failed)
    case "delivered" => Some(Delivered)
    case "deferred" => Some(Failed)
    case "bounce" => Some(Bounce)
    case _ => None
  }

  def fromTwilioEvent(twilioEvent: String): Option[Int] = twilioEvent match {
    case "accepted" => Some(Triggered)
    case "queued" => Some(Triggered)
    case "sent" => Some(Triggered)
    case "failed" => Some(Failed)
    case "delivered" => Some(Delivered)
    case "undelivered" => Some(Undelivered)
    case _ => None
  }
}