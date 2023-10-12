//
//  AlertFeedbackStep.swift
//  Flo
//
//  Created by Nicolás Stefoni on 15/03/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

internal enum AlertFeedbackAction: String {
    case sleep2Hs = "sleep_2h", sleep24Hs = "sleep_24h"
    
    var snoozeSeconds: Int {
        switch self {
        case .sleep2Hs:
            return 7200
        case .sleep24Hs:
            return 86400
        }
    }
}

internal class AlertFeedbackStep: JsonParsingProtocol {
    
    public let displayText: String
    public let sortOrder: Int
    public let property: String?
    public let value: AnyObject
    public let action: AlertFeedbackAction?
    
    fileprivate var _flow: AlertFeedbackFlow?
    public var flow: AlertFeedbackFlow? {
        if let tag = _flow?.tag {
            return AlertFeedbackFlow.customFlows[tag]
        }
        
        return _flow
    }
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        displayText = json["displayText"].stringValue
        sortOrder = json["sortOrder"].intValue
        property = json["property"].string
        value = json["value"].object as AnyObject
        action = AlertFeedbackAction(rawValue: json["action"].stringValue)
        
        if let flowDictionaryObject = json["flow"].dictionaryObject {
            _flow = AlertFeedbackFlow(flowDictionaryObject as AnyObject)
        }
    }
    
    public class func array(_ objects: [Any]?) -> [AlertFeedbackStep] {
        var feedbackSteps: [AlertFeedbackStep] = []
        
        for object in objects ?? [] {
            if let feedbackStep = AlertFeedbackStep(object as AnyObject) {
                feedbackSteps.append(feedbackStep)
            }
        }
        
        return feedbackSteps
    }
    
}
