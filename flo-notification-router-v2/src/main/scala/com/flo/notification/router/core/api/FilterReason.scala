package com.flo.notification.router.core.api

sealed trait FilterReason
sealed trait DeliveryFilterReason       extends FilterReason
sealed trait AutoResolutionFilterReason extends FilterReason

case object DeliverySettingsNoMediumsAllowed extends DeliveryFilterReason
case object DeliverySettingsNotFound         extends DeliveryFilterReason
case object AlarmNoMediumsAllowed            extends DeliveryFilterReason
case object AlarmsMuted                      extends DeliveryFilterReason

case object SmallDripSensitivity extends AutoResolutionFilterReason

case object MaxDeliveryFrequencyCap          extends FilterReason
case object MultipleFilterMerge              extends FilterReason
case object Cleared                          extends FilterReason
case object Snoozed                          extends FilterReason
case object AlarmIsInternal                  extends FilterReason
case object AlarmIsDisabled                  extends FilterReason
case object Expired                          extends FilterReason
case object PointsLimitNotReachedForCategory extends FilterReason
case object ValveClosed                      extends FilterReason
case object DeviceUnpaired                   extends FilterReason
case object DeviceAlertStatus                extends FilterReason
case object SleepMode                        extends FilterReason
case object FloSenseInSchedule               extends FilterReason
case object FloSenseLevelNotReached          extends FilterReason
case object FloSenseShutoffNotTriggered      extends FilterReason
