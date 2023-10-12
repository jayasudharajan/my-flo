//
//  AlertModel.swift
//  Flo
//
//  Created by Josefina Perez on 30/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

internal enum AlertSeverity: String {
    case info, warning, critical
    
    var name: String {
        switch self {
        case .critical:
            return "critical_alerts".localized
        case .warning:
            return "warning_alerts".localized
        case .info:
            return "informative_alerts".localized
        }
    }
    
    var color: UIColor {
        switch self {
        case .critical:
            return StyleHelper.colors.red
        case .warning:
            return StyleHelper.colors.orange
        case .info:
            return StyleHelper.colors.infoBlue
        }
    }
    
    var icon: UIImage {
        switch self {
        case .critical:
            return UIImage(named: "red-round-alert-icon") ?? UIImage()
        case .warning:
            return UIImage(named: "orange-round-alert-icon") ?? UIImage()
        case .info:
            return UIImage(named: "blue-round-info-icon") ?? UIImage()
        }
    }
}

internal enum HealthTestDripSensitivity: String {
    case any = "4"
    case small = "3"
    case bigger = "2"
    case biggest = "1"
}

internal class AlertModel: JsonParsingProtocol {
    
    public let id: Int
    public let name: String
    public let severity: AlertSeverity
    public let isInternal: Bool
    public let isShutoff: Bool
    public let isActive: Bool
    public let isConfigurable: Bool
    public let hasParent: Bool
    public let triggersAlert: Int
    public var children: [Int] = []
    public var url: URL?
    
    public var feedbackFlows: [SystemMode: AlertFeedbackFlow] = [:]
    public let actions: [AlertResolutionAction]
    
    public var isFloSenseAlarm: Bool {
        return id > 69 && id < 90
    }

    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        id = json["id"].intValue
        name = json["displayName"].stringValue
        severity = AlertSeverity(rawValue: json["severity"].stringValue) ?? .info
        isInternal = json["isInternal"].boolValue
        isShutoff = json["isShutoff"].boolValue
        isActive = json["active"].boolValue
        isConfigurable = json["deliveryMedium"]["userConfigurable"].boolValue
        hasParent = json["parent"]["id"].int != nil
        
        triggersAlert = json["triggersAlarm"]["id"].intValue
        
        for child in json["children"].arrayValue {
            if let id = child["id"].int {
                children.append(id)
            }
        }
        
        for supportOption in json["supportOptions"].arrayValue {
            if let actionPath = supportOption["actionPath"].string {
                self.url = URL(string: "https://" + actionPath + "/1")
                break
            }
        }
        
        let userFeedbackFlowArray = json["userFeedbackFlow"].arrayValue
        for userFeedbackFlow in userFeedbackFlowArray {
            if let systemMode = SystemMode(rawValue: userFeedbackFlow["systemMode"].stringValue) {
                if let customFlowDicts = userFeedbackFlow["flowTags"].dictionary {
                    AlertFeedbackFlow.customFlows(customFlowDicts)
                }
                if let feedbackFlow = userFeedbackFlow["flow"].dictionary {
                    feedbackFlows[systemMode] = AlertFeedbackFlow(feedbackFlow as AnyObject)
                }
            }
        }
        
        actions = AlertResolutionAction.array(json["actions"].arrayObject)
    }
    
    public class func array(_ objects: [Any]?) -> [AlertModel] {
        var alerts: [AlertModel] = []
        
        for object in objects ?? [] {
            if let alert = AlertModel(object as AnyObject) {
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
}

internal class AlertSettings: JsonParsingProtocol {
    
    public let alertId: Int
    public let systemMode: SystemMode
    public var smsEnabled: Bool
    public var emailEnabled: Bool
    public var pushEnabled: Bool
    public var callEnabled: Bool
    
    init(alertId: Int, systemMode: SystemMode) {
        self.alertId = alertId
        self.systemMode = systemMode
        smsEnabled = true
        emailEnabled = true
        pushEnabled = true
        callEnabled = true
    }
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        alertId = json["alarmId"].intValue
        systemMode = SystemMode(rawValue: json["systemMode"].stringValue) ?? .home
        smsEnabled = json["smsEnabled"].bool ?? true
        emailEnabled = json["emailEnabled"].bool ?? true
        pushEnabled = json["pushEnabled"].bool ?? true
        callEnabled = json["callEnabled"].bool ?? true
    }
    
    public class func array(_ objects: [Any]?) -> [AlertSettings] {
        var settings: [AlertSettings] = []
        
        for object in objects ?? [] {
            if let setting = AlertSettings(object as AnyObject) {
                settings.append(setting)
            }
        }
        
        return settings
    }
    
}
