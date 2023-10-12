package main

import "time"

func startPresenceAlerts() {
	logDebug("startPresenceAlerts: starting processing for presence alerts")
	go presenceAlertsWorker(DEVICE_MAKE_SHUTOFF_V2)
	go presenceAlertsWorker(DEVICE_MAKE_DETECTOR)
}

func presenceAlertsWorker(deviceMake string) {
	presenceAlertTimer := time.NewTicker(2 * time.Minute)

	for {
		select {
		case <-presenceAlertTimer.C:
			// Scan for devices that need an offline alert
			go func() {
				logDebug("presenceAlertsWorker: processing offline for %v", deviceMake)
				err := alertOfflineDevices(_dbCn, _redis, queryOffline, sendOfflineAlert, markOfflineSent, deviceMake)

				if err != nil {
					logDebug("failed to alert offline %v %v", deviceMake, err.Error())
				}
			}()

			// Scan for devices that need a still offline alert
			go func() {
				logDebug("presenceAlertsworker: processing still offline for %v", deviceMake)
				err := alertOfflineDevices(_dbCn, _redis, queryStillOffline, sendStillOfflineAlert, markStillOfflineSent, deviceMake)

				if err != nil {
					logDebug("failed to alert still offline %v %v", deviceMake, err.Error())
				}
			}()
		}
	}
}
