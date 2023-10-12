package com.flo.notification.router.core

import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService

import scala.concurrent.ExecutionContext

trait Module {

  // Requires
  def defaultExecutionContext: ExecutionContext
  def deserializationErrors: Set[Class[_ <: Throwable]]
  def alarmIncidentConsumer: Consumer[AlarmIncidentProcessor]
  def alertStatusConsumer: Consumer[AlertStatusProcessor]
  def entityActivityConsumer: Consumer[EntityActivityProcessor]
  def retrieveUsersByMacAddress: UsersByMacAddressRetriever
  def deliverAlarmIncident: AlarmIncidentDelivery
  def applyAlarmIncidentFilters: AlarmIncidentFilter
  def retrieveAlarm: AlarmRetriever
  def registerIncident: RegisterIncident
  def localizationService: LocalizationService
  def resolveHealthTestRelatedAlarms: HealthTestRelatedAlarmsResolver
  def resolvePendingAlerts: PendingAlertResolver
  def resolvePendingAlertsForAlarm: PendingAlertsForAlarmResolver
  def convertToAlarmIncident: AlarmIncidentConverter
  def cancelDelivery: DeliveryCancel
  def cleanUpDeviceData: DeviceDataCleanUp

  // Private
  private val processAlarmIncident =
    new ProcessAlarmIncident(
      retrieveUsersByMacAddress,
      retrieveAlarm,
      deliverAlarmIncident,
      applyAlarmIncidentFilters,
      registerIncident,
      localizationService,
      resolveHealthTestRelatedAlarms
    )(defaultExecutionContext)

  private val processAlertStatus = new ProcessAlertStatus(
    retrieveUsersByMacAddress,
    resolvePendingAlertsForAlarm,
    convertToAlarmIncident,
    processAlarmIncident,
    cancelDelivery
  )(defaultExecutionContext)

  private val processEntityActivity = new ProcessEntityActivity(
    resolvePendingAlerts,
    cleanUpDeviceData
  )(defaultExecutionContext)

  alarmIncidentConsumer.start(processAlarmIncident, Some(deserializationErrors))

  alertStatusConsumer.start(processAlertStatus, Some(deserializationErrors))

  entityActivityConsumer.start(processEntityActivity)

  sys.addShutdownHook {
    alarmIncidentConsumer.stop()
    alertStatusConsumer.stop()
    entityActivityConsumer.stop()
  }
}
