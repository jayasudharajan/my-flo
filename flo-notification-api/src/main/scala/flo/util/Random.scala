package flo.util

import com.flo.notification.sdk.model.{
  AlertFeedbackFlow,
  AlertFeedbackStep,
  AlertFeedbackStepOption,
  FeedbackOption,
  UserFeedbackOptions
}
import com.softwaremill.quicklens._

import scala.annotation.tailrec
import scala.util.{Random => ScalaRandom}
import scala.util.hashing.MurmurHash3

object Random {
  def randomizeUserFeedbackOptions(userFeedbackOptions: UserFeedbackOptions,
                                   alarmId: Int,
                                   userId: Option[String]): UserFeedbackOptions =
    if (ConfigUtils.randomizeUserFeedbackOptions)
      userFeedbackOptions
        .modify(_.feedback)
        .using(f => randomizeFeedbackOptions(Seq(f), alarmId, userId).head)
        .modify(_.optionsKeyList)
        .using(o => randomizeFeedbackOptions(o, alarmId, userId))
    else userFeedbackOptions

  def randomizeFeedbackOptions(feedbackOptions: Seq[FeedbackOption],
                               alarmId: Int,
                               userId: Option[String]): Seq[FeedbackOption] = {
    val nonRandomizable = feedbackOptions.view
      .filterNot(_.sortRandom.getOrElse(false))
      .sortBy(_.sortOrder.getOrElse(Int.MaxValue))
      .force

    val randomizable = feedbackOptions.filter(_.sortRandom.contains(true))

    val randomizedOrders = {
      val orders = List.range(0, randomizable.size)
      val seed   = MurmurHash3.seqHash(List(alarmId, userId.fold(0)(_.hashCode)))
      val r      = new ScalaRandom(seed)
      r.shuffle(orders)
    }

    val nonRandomizableOrders = List.range(randomizable.size, randomizable.size + nonRandomizable.size)

    val randomizedOptions = (randomizable, randomizedOrders).zipped.map { (option, order) =>
      option
        .modify(_.sortOrder)
        .setTo(Some(order))
        .modify(_.options.each)
        .using(randomizeFeedbackOptions(_, alarmId, userId))
    }

    val nonRandomizableOptions = (nonRandomizable, nonRandomizableOrders).zipped.map { (option, order) =>
      option
        .modify(_.sortOrder)
        .setTo(Some(order))
        .modify(_.options.each)
        .using(randomizeFeedbackOptions(_, alarmId, userId))
    }

    (randomizedOptions ++ nonRandomizableOptions).sortBy(_.sortOrder.getOrElse(Int.MaxValue))
  }

  def randomizeFeedbackFlows(alertFeedbackFlows: Seq[AlertFeedbackFlow],
                             userId: Option[String]): Seq[AlertFeedbackFlow] =
    if (ConfigUtils.randomizeFeedbackFlowOptions) randomizeFeedbackFlows(alertFeedbackFlows, userId, Seq())
    else alertFeedbackFlows

  @tailrec
  private def randomizeFeedbackFlows(alertFeedbackFlows: Seq[AlertFeedbackFlow],
                                     userId: Option[String],
                                     sortedFlows: Seq[AlertFeedbackFlow]): Seq[AlertFeedbackFlow] =
    alertFeedbackFlows match {
      case Seq() => sortedFlows

      case Seq(head, tail @ _*) =>
        val sortedFlow = head.modify(_.flow).using(randomizeFeedbackFlowStep(_, head.alarmId, userId))
        randomizeFeedbackFlows(tail, userId, sortedFlows :+ sortedFlow)
    }

  private def randomizeFeedbackFlowStep(alertFeedbackStep: AlertFeedbackStep,
                                        alarmId: Int,
                                        userId: Option[String]): AlertFeedbackStep =
    alertFeedbackStep
      .modify(_.options)
      .using(randomizeOptions(_, alarmId, userId))

  private def randomizeOptions(options: Seq[AlertFeedbackStepOption],
                               alarmId: Int,
                               userId: Option[String]): Seq[AlertFeedbackStepOption] = {

    val nonRandomizable = options.view
      .filterNot(_.sortRandom.getOrElse(false))
      .sortBy(_.sortOrder.getOrElse(Int.MaxValue))
      .force

    val randomizable = options.filter(_.sortRandom.contains(true))

    val randomizedOrders = {
      val orders = List.range(0, randomizable.size)
      val seed   = MurmurHash3.seqHash(List(alarmId, userId.fold(0)(_.hashCode)))
      val r      = new ScalaRandom(seed)
      r.shuffle(orders)
    }

    val nonRandomizableOrders = List.range(randomizable.size, randomizable.size + nonRandomizable.size)

    val randomizedOptions = (randomizable, randomizedOrders).zipped.map { (option, order) =>
      option
        .modify(_.sortOrder)
        .setTo(Some(order))
        .modify(_.flow.each.eachRight)
        .using(randomizeFeedbackFlowStep(_, alarmId, userId))
    }

    val nonRandomizableOptions = (nonRandomizable, nonRandomizableOrders).zipped.map { (option, order) =>
      option
        .modify(_.sortOrder)
        .setTo(Some(order))
        .modify(_.flow.each.eachRight)
        .using(randomizeFeedbackFlowStep(_, alarmId, userId))
    }

    (randomizedOptions ++ nonRandomizableOptions).sortBy(_.sortOrder.getOrElse(Int.MaxValue))
  }
}
