//
//  EventModel.swift
//  Flo
//
//  Created by Josefina Perez on 09/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SwiftyJSON

internal class EventModel: JsonParsingProtocol {
    
    public let id: String
    public var alert: AlertModel?
    public let device: DeviceModel?
    public let status: String
    public let snoozeTo: Date
    public let location: LocationModel?
    public let systemMode: SystemMode
    public let createdAt: Date
    public let resolutionDate: Date?
    public let displayTitle: String
    public let displayMessage: String
    public let gpm: Double
    public let galUsed: Double
    public let leakLossMaxGal: Double
    public let psiDelta: Double
    public let duration: Double
    public let roundId: String?
    
    public var feedbackFlow: AlertFeedbackFlow? {
        return alert?.feedbackFlows[systemMode]
    }

    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        id = json["id"].stringValue
        let alertId = json["alarm"]["id"].intValue
        alert = AlertsManager.shared.getAlertLocally(alertId)
        let deviceId = json["deviceId"].stringValue
        device = DevicesHelper.getOneLocally(deviceId)
        status = json["status"].stringValue
        snoozeTo = Date.iso8601ToDate(json["snoozeTo"].stringValue) ?? Date()
        let locationId = json["locationId"].stringValue
        location = LocationsManager.shared.getOneLocally(locationId)
        systemMode = SystemMode(rawValue: json["systemMode"].stringValue) ?? .home
        createdAt = Date.iso8601ToDate(json["createAt"].stringValue) ?? Date()
        resolutionDate = Date.iso8601ToDate(json["resolutionDate"].stringValue)
        displayTitle = json["displayTitle"].stringValue
        displayMessage = json["displayMessage"].stringValue
        let fwValuesDict = json["fwValues"].dictionaryValue
        gpm = fwValuesDict["gpm"]?.doubleValue ?? 0
        galUsed = fwValuesDict["galUsed"]?.doubleValue ?? 0
        leakLossMaxGal = fwValuesDict["leakLossMaxGal"]?.doubleValue ?? 0
        psiDelta = abs(fwValuesDict["psiDelta"]?.doubleValue ?? 0)
        duration = fwValuesDict["flowEventDuration"]?.doubleValue ?? 0
        roundId = json["healthTest"]["roundId"].string
    }
    
    public class func array(_ objects: [Any]?) -> [EventModel] {
        var events: [EventModel] = []
        
        for object in objects ?? [] {
            if let event = EventModel(object as AnyObject) {
                events.append(event)
            }
        }
        
        return events
    }
    
}
