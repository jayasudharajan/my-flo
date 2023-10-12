package flo.services

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.localization.{LocalizeAssetRequest, LocalizeAssetRequestList, LocalizedApi}
import com.flo.FloApi.localization.api.LocalizedAsset
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsGrantInfo, FloTokenProviders, OAuth2AuthProvider}
import com.flo.notification.sdk.model.{
  ActionSupport,
  AlertFeedbackFlow,
  AlertFeedbackStepOption,
  FeedbackOption,
  UserFeedbackOptions
}
import com.flo.utils.{HttpMetrics, IHttpMetrics}
import kamon.Kamon
import com.softwaremill.quicklens._
import com.twitter.logging.Logger
import javax.inject.{Inject, Singleton}
import perfolation._

import scala.annotation.tailrec
import scala.concurrent.{ExecutionContext, Future}

@Singleton
class LocalizationService @Inject()(implicit ec: ExecutionContext,
                                    actorSystem: ActorSystem,
                                    actorMaterializer: ActorMaterializer) {

  private val log = Logger.get(getClass)

  private val httpMetrics: IHttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-localization-service",
    tags = Map("service-name" -> "flo-notification-api-v2")
  )
  private val tokenProvider =
    FloTokenProviders.getClientCredentialsProvider()(actorSystem, actorMaterializer, httpMetrics)

  private val authProvider = new OAuth2AuthProvider[ClientCredentialsGrantInfo](tokenProvider)
  private val localization = new LocalizedApi()(authProvider)(actorSystem, actorMaterializer, httpMetrics)

  def getLocalization(asset: String, assetType: String, locale: String): Future[String] =
    localization.getLocalized(asset, assetType, locale, Map()).map(_.localizedValue)

  def getLocalizedAlarmDisplayName(alarmId: String, locale: String): Future[DisplayNameAndDescription] = {
    val assetRequests = LocalizeAssetRequestList(buildNameAndDescriptionRequest(alarmId, locale))

    localization.getLocalized(assetRequests).map { response =>
      extractNamesAndDescriptions(response.items).headOption.map(_._2).getOrElse(DisplayNameAndDescription.empty())
    }
  }

  def getLocalizedAlarmsDisplayName(alarmIds: Set[String],
                                    locale: String): Future[Map[String, DisplayNameAndDescription]] = {
    val assetRequests = LocalizeAssetRequestList(
      alarmIds.flatMap(a => buildNameAndDescriptionRequest(a, locale)).toList
    )

    localization.getLocalized(assetRequests).map { response =>
      if (response.errors.nonEmpty) log.warning(s"Error while retrieving certain localizations. ${response.errors}")

      extractNamesAndDescriptions(response.items)
    }
  }

  def localizeActionDisplayNameAndDescription(locale: String): Future[DisplayNameAndDescription] = {
    val assetRequests = LocalizeAssetRequestList(
      List(
        LocalizeAssetRequest(p"nr.actions.title", "display", locale, Map()),
        LocalizeAssetRequest(p"nr.actions.description", "display", locale, Map())
      )
    )

    localization.getLocalized(assetRequests).map { response =>
      if (response.errors.nonEmpty) log.warning(s"Error while retrieving certain localizations. ${response.errors}")

      val localizedAssetMap: Map[String, String] = response.items.map { item =>
        item.name -> item.localizedValue
      }(scala.collection.breakOut)

      val displayName = localizedAssetMap.getOrElse(p"nr.actions.title", "")
      val description = localizedAssetMap.getOrElse(p"nr.actions.description", "")

      DisplayNameAndDescription(displayName, description)
    }
  }

  def localizeUserFeedbackOptions(userFeedbackOptions: Seq[UserFeedbackOptions],
                                  locale: String): Future[Seq[UserFeedbackOptions]] = {
    val assetRequests = userFeedbackOptionsToAssetRequests(userFeedbackOptions, locale)
    localization.getLocalized(assetRequests).map { response =>
      if (response.errors.nonEmpty)
        log.warning(p"Missing localization assets (this may be expected): ${response.errors}")

      val localizedAssetMap: Map[String, String] = response.items.map { item =>
        item.name -> item.localizedValue
      }(scala.collection.breakOut)

      setLocalizedValuesToUserFeedbackOptions(userFeedbackOptions, localizedAssetMap)
    }
  }

  private def userFeedbackOptionsToAssetRequests(userFeedbackOptions: Seq[UserFeedbackOptions],
                                                 locale: String): LocalizeAssetRequestList = {
    val assetNames = userFeedbackOptions.flatMap { o =>
      val feedbackAssetNames = feedbackOptionToAssetNames(p"nr.userFeedbackOptions", o.feedback)
      val optionKeyListAssetNames =
        o.optionsKeyList.flatMap(o => feedbackOptionToAssetNames(p"nr.userFeedbackOptions", o))
      feedbackAssetNames ++ optionKeyListAssetNames
    }

    LocalizeAssetRequestList(assetNames.map { assetName =>
      LocalizeAssetRequest(assetName, "display", locale, Map())
    }.toList)
  }

  private def feedbackOptionToAssetNames(prefix: String, feedbackOption: FeedbackOption): Set[String] = {
    val displayNameAssetName  = p"$prefix.${feedbackOption.id}.displayName"
    val displayTitleAssetName = p"$prefix.${feedbackOption.id}.displayTitle"
    val optionsAssetNames = feedbackOption.options
      .map(_.flatMap { o =>
        feedbackOptionToAssetNames(p"$prefix.${feedbackOption.id}.options", o)
      })
      .getOrElse(Set())

    Set(displayNameAssetName, displayTitleAssetName) ++ optionsAssetNames
  }

  private def setLocalizedValuesToUserFeedbackOptions(
      userFeedbackOptions: Seq[UserFeedbackOptions],
      localizedAssetMap: Map[String, String]
  ): Seq[UserFeedbackOptions] =
    userFeedbackOptions.map { options =>
      options
        .modify(_.feedback)
        .using(f => setLocalizedValuesToFeedbackOption(p"nr.userFeedbackOptions", f, localizedAssetMap))
        .modify(_.optionsKeyList)
        .using(_.map(o => setLocalizedValuesToFeedbackOption(p"nr.userFeedbackOptions", o, localizedAssetMap)))
    }

  private def setLocalizedValuesToFeedbackOption(prefix: String,
                                                 feedbackOption: FeedbackOption,
                                                 localizedAssetMap: Map[String, String]): FeedbackOption =
    feedbackOption
      .modify(_.displayName)
      .setToIfDefined(localizedAssetMap.get(p"$prefix.${feedbackOption.id}.displayName").map(Option(_)))
      .modify(_.displayTitle)
      .setToIfDefined(localizedAssetMap.get(p"$prefix.${feedbackOption.id}.displayTitle").map(Option(_)))
      .modify(_.options)
      .using(
        _.map(
          _.map(o => setLocalizedValuesToFeedbackOption(p"$prefix.${feedbackOption.id}.options", o, localizedAssetMap))
        )
      )

  def localizeActionSupportList(actionSupportList: Seq[ActionSupport], locale: String): Future[Seq[ActionSupport]] = {
    val assets = Set(actionSupportList.flatMap { actionSupport =>
      actionSupport.actions.map { action =>
        LocalizeAssetRequest(p"nr.actions.${action.id}", "display", locale, Map())
      }
    }: _*).toList

    val assetRequests = LocalizeAssetRequestList(assets)

    localization.getLocalized(assetRequests).map { response =>
      if (response.errors.nonEmpty) log.warning(p"Error while retrieving certain localizations. ${response.errors}")

      val localizedAssetMap: Map[String, String] = response.items.map { item =>
        item.name -> item.localizedValue
      }(scala.collection.breakOut)

      actionSupportList.map { actionSupport =>
        actionSupport.modify(_.actions.each).using { action =>
          action.modify(_.text).setToIfDefined(localizedAssetMap.get(p"nr.actions.${action.id}"))
        }
      }
    }
  }

  // TODO: Let's make the world a better place and improve the following code (feedback flow localization).
  // I apologize for writing such cryptic and obfuscated code.
  def localizeFeedbackFlows(feedbackFlows: Seq[AlertFeedbackFlow], locale: String): Future[Seq[AlertFeedbackFlow]] = {
    val assetRequests = feedbackFlowsToAssetRequests(feedbackFlows, locale)

    localization.getLocalized(assetRequests).map { response =>
      if (response.errors.nonEmpty) log.warning(p"Error while retrieving certain localizations. ${response.errors}")

      val localizedAssetMap: Map[String, String] = response.items.map { item =>
        item.name -> item.localizedValue
      }(scala.collection.breakOut)

      feedbackFlows
        .map { feedbackFlow =>
          feedbackFlow
            .modify(_.flow.titleText)
            .setToIfDefined {
              localizedAssetMap.get(p"alertFeedbackFlow.alarms.${feedbackFlow.alarmId}.title")
            }
            .modify(_.flow.options)
            .setTo(localizeOptions(feedbackFlow.flow.options, localizedAssetMap))
            .modify(_.flowTags)
            .setTo {
              feedbackFlow.flowTags.map {
                case (tag, v) =>
                  tag -> v
                    .modify(_.titleText)
                    .setToIfDefined {
                      localizedAssetMap.get(p"alertFeedbackFlow.tags.$tag.title")
                    }
                    .modify(_.options)
                    .setTo {
                      v.options.map { stepOption =>
                        stepOption.modify(_.displayText.each).setToIfDefined {
                          localizedAssetMap.get(
                            p"alertFeedbackFlow.tags.$tag.options.${stepOption.property}.${stepOption.value}"
                          )
                        }
                      }
                    }
              }
            }
        }
    }
  }

  def feedbackFlowsToAssetRequests(feedbackFlows: Seq[AlertFeedbackFlow], locale: String): LocalizeAssetRequestList = {
    val feedbackFlowTitles = feedbackFlows.map { feedbackFlow =>
      p"alertFeedbackFlow.alarms.${feedbackFlow.alarmId}.title"
    }.toSet

    val tagTitles = feedbackFlows.flatMap { feedbackFlow =>
      feedbackFlow.flowTags.keys.map { tag =>
        p"alertFeedbackFlow.tags.$tag.title"
      }
    }.toSet

    val tagOptions = feedbackFlows.flatMap { feedbackFlow =>
      feedbackFlow.flowTags.flatMap {
        case (key, feedbackStep) =>
          feedbackStep.options.map { feedbackStepOption =>
            p"alertFeedbackFlow.tags.$key.options.${feedbackStepOption.property}.${feedbackStepOption.value}"
          }
      }
    }.toSet

    val flowOptions = feedbackFlows.flatMap { feedbackFlow =>
      extractFlowOptions(feedbackFlow.flow.options, Set())
    }

    LocalizeAssetRequestList(
      (feedbackFlowTitles ++ tagTitles ++ tagOptions ++ flowOptions).map { assetName =>
        LocalizeAssetRequest(assetName, "display", locale, Map())
      }.toList
    )
  }

  @tailrec
  private def extractFlowOptions(flowOptions: Seq[AlertFeedbackStepOption],
                                 optionAssetNames: Set[String]): Set[String] =
    flowOptions match {
      case Seq() => optionAssetNames

      case Seq(head, tail @ _*) =>
        val updatedAssetNames = optionAssetNames ++ head.displayText.fold {
          Set(p"alertFeedbackFlow.properties.${head.property}.title")
        } { _ =>
          Set(
            p"alertFeedbackFlow.properties.${head.property}.title",
            p"alertFeedbackFlow.properties.${head.property}.${head.value}"
          )
        }
        val updatedTail = tail ++ head.flow.fold(Seq.empty[AlertFeedbackStepOption]) { flow =>
          flow.fold(_ => Seq.empty[AlertFeedbackStepOption], feedbackStepOption => feedbackStepOption.options)
        }
        extractFlowOptions(updatedTail, updatedAssetNames)
    }

  private def localizeOptions(options: Seq[AlertFeedbackStepOption],
                              localizedAssetMap: Map[String, String]): Seq[AlertFeedbackStepOption] =
    localizeOptions(options, localizedAssetMap, Seq.empty)

  private def localizeOptions(options: Seq[AlertFeedbackStepOption],
                              localizedAssetMap: Map[String, String],
                              localizedOptions: Seq[AlertFeedbackStepOption]): Seq[AlertFeedbackStepOption] =
    options match {
      case Seq() => localizedOptions

      case Seq(head, tail @ _*) =>
        val updatedOption = head
          .modify(_.displayText.each)
          .setToIfDefined {
            localizedAssetMap.get(p"alertFeedbackFlow.properties.${head.property}.${head.value}")
          }
          .modify(_.flow.each.eachRight.titleText)
          .setToIfDefined {
            head.flow.flatMap { flow =>
              flow.toOption.flatMap { step =>
                step.options.headOption.flatMap { option =>
                  localizedAssetMap.get(p"alertFeedbackFlow.properties.${option.property}.title")
                }
              }
            }
          }
          .modify(_.flow.each.eachRight.options)
          .usingIf {
            head.flow.exists(_.exists(_.options.nonEmpty))
          }(localizeOptions(_, localizedAssetMap, Seq.empty))

        val updatedLocalizedOptions = localizedOptions :+ updatedOption
        localizeOptions(tail, localizedAssetMap, updatedLocalizedOptions)
    }

  private def buildNameAndDescriptionRequest(alarmId: String, locale: String): List[LocalizeAssetRequest] =
    List(
      LocalizeAssetRequest(s"nr.alarm.$alarmId.name", "display", locale, Map()),
      LocalizeAssetRequest(s"nr.alarm.$alarmId.description", "display", locale, Map())
    )

  private val AlarmIdExtractor = "nr\\.alarm\\.([0-9]+)\\..*".r
  private def extractNamesAndDescriptions(assets: List[LocalizedAsset]): Map[String, DisplayNameAndDescription] = {

    @tailrec
    def extractNamesAndDescriptions(
        assets: List[LocalizedAsset],
        nameMap: Map[String, DisplayNameAndDescription]
    ): Map[String, DisplayNameAndDescription] =
      assets match {
        case asset :: tail =>
          val AlarmIdExtractor(alarmId) = asset.name
          val updatedNameAndDescription = nameMap
            .getOrElse(alarmId, DisplayNameAndDescription.empty())
            .modify(_.displayName)
            .setToIf(asset.name.endsWith("name"))(asset.localizedValue)
            .modify(_.description)
            .setToIf(asset.name.endsWith("description"))(asset.localizedValue)

          extractNamesAndDescriptions(tail, nameMap + (alarmId -> updatedNameAndDescription))

        case Nil => nameMap
      }

    extractNamesAndDescriptions(assets, Map())
  }
}

case class DisplayNameAndDescription(displayName: String, description: String)

object DisplayNameAndDescription {
  def empty(): DisplayNameAndDescription = DisplayNameAndDescription("", "")
}
