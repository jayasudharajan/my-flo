//
//  AlertsManager.swift
//  Flo
//
//  Created by Josefina Perez on 31/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SwiftyJSON

class AlertsManager: NSObject {
    
    // MARK: - Singleton
    static let shared = AlertsManager()
    
    public var alerts: [AlertModel] = []
    public var settings: [AlertSettings] = []
    public var healthTestDripSensitivity: HealthTestDripSensitivity = .any
    
    public func getAlerts(whenFinished: @escaping (FloRequestErrorModel?, [AlertModel]) -> Void) {
        FloApiRequest(
            controller: "v2/alarms",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                guard
                    let dict = data as? NSDictionary,
                    let list = dict["items"] as? [Any]
                else {
                    whenFinished(error, [])
                    return
                }
                self.alerts = AlertModel.array(list).sorted(by: { $0.name < $1.name })
                
                whenFinished(error, self.alerts)
            }
        ).secureFloRequest()
    }
    
    public func getAlertsSettings(deviceId: String, whenFinished: @escaping (FloRequestErrorModel?, [AlertSettings]?,
        HealthTestDripSensitivity) -> Void) {
        
        guard let userId = UserSessionManager.shared.user?.id else {
            return
        }
        
        FloApiRequest(
            controller: "v2/users/\(userId)?expand=alarmSettings",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                guard let alertsSettingsJson = JSON(data as Any).dictionary?["alarmSettings"] else {
                    whenFinished(error, nil, self.healthTestDripSensitivity)
                    return
                }
                
                for deviceSettingsJson in alertsSettingsJson.arrayValue {
                    guard
                        let jsonDeviceId = deviceSettingsJson["deviceId"].string,
                        jsonDeviceId == deviceId,
                        let settingsArrayObject = deviceSettingsJson["settings"].arrayObject
                    else { continue }
                    
                    self.healthTestDripSensitivity = HealthTestDripSensitivity(rawValue: deviceSettingsJson["smallDripSensitivity"].stringValue) ?? .any
                    
                    self.settings = AlertSettings.array(settingsArrayObject)
                    whenFinished(error, self.settings, self.healthTestDripSensitivity)
                    
                    break
                }
                
                whenFinished(error, [], self.healthTestDripSensitivity)
            }
        ).secureFloRequest()
    }
    
    public func getEventsFor(deviceIds: [String], page: Int, size: Int, whenFinished: @escaping (FloRequestErrorModel?, [EventModel]) -> Void) {
        if deviceIds.isEmpty {
            whenFinished(nil, [])
            return
        }
        
        var query = "?page=\(page)&size=\(size)"
        for i in 0 ..< deviceIds.count {
            query += "&deviceId=" + deviceIds[i]
        }
        
        FloApiRequest(
            controller: "v2/alerts" + query,
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                if let e = error {
                    whenFinished(e, [])
                } else {
                    guard
                        let dict = data as? NSDictionary,
                        let list = dict["items"] as? [Any]
                    else {
                        whenFinished(nil, [])
                        return
                    }
                    
                    var events = EventModel.array(list)
                    events.sort(by: { $0.createdAt > $1.createdAt })
                    
                    whenFinished(nil, events)
                }
            }
        ).secureFloRequest()
    }
    
    public func getTopEventsFor(deviceIds: [String], whenFinished: @escaping (FloRequestErrorModel?, [EventModel]) -> Void) {
        if deviceIds.isEmpty {
            whenFinished(nil, [])
            return
        }
        
        var query = "?status=triggered"
        for i in 0 ..< deviceIds.count {
            query += "&deviceId=" + deviceIds[i]
        }
        
        FloApiRequest(
            controller: "v2/alerts" + query,
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                if let e = error {
                    whenFinished(e, [])
                } else {
                    guard
                        let dict = data as? NSDictionary,
                        let list = dict["items"] as? [Any]
                    else {
                        whenFinished(nil, [])
                        return
                    }
                    
                    var events = EventModel.array(list)
                    events.sort(by: { $0.createdAt > $1.createdAt })
                    
                    var notRepeatedEvents: [EventModel] = []
                    for i in 0 ..< events.count {
                        if let alert = events[i].alert, alert.severity != .info, let deviceId = events[i].device?.id {
                            var alreadyThere = false
                            for event in notRepeatedEvents where event.alert?.id == alert.id && event.device?.id == deviceId {
                                alreadyThere = true
                                break
                            }
                            if !alreadyThere {
                                notRepeatedEvents.append(events[i])
                            }
                        }
                    }
                    
                    whenFinished(nil, notRepeatedEvents)
                }
            }
        ).secureFloRequest()
    }
    
    public func getSettingsForAlert(id: Int, systemMode: SystemMode) -> AlertSettings {
        guard let settings = settings.first(where: { $0.alertId == id && $0.systemMode == systemMode}) else {
            return AlertSettings(alertId: id, systemMode: systemMode)
        }
        
        return settings
    }
    
    public func getAlert(_ id: Int, callback: @escaping (AlertModel?) -> Void) {
        FloApiRequest(
            controller: "v2/alarms/\(id)",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (_, data) in
                if let d = data as? NSDictionary, let alert = AlertModel(d) {
                    callback(alert)
                } else {
                    callback(nil)
                }
            }
        ).secureFloRequest()
    }
    
    public func getAlertLocally(_ id: Int) -> AlertModel? {
        return alerts.first(where: { $0.id == id })
    }
    
    public func getEvent(_ id: String, callback: @escaping (EventModel?) -> Void) {
        FloApiRequest(
            controller: "v2/alerts/\(id)",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (_, data) in
                if let d = data as? NSDictionary, let event = EventModel(d) {
                    if event.alert != nil {
                        callback(event)
                    } else if let alertDict = d["alarm"] as? NSDictionary, let alertId = alertDict["id"] as? Int {
                        self.getAlert(alertId, callback: { (alert) in
                            event.alert = alert
                            callback(event)
                        })
                    } else {
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
            }
        ).secureFloRequest()
    }
    
}
