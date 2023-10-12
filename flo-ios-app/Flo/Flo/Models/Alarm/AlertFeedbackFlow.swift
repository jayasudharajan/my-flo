//
//  AlertFeedbackFlow.swift
//  Flo
//
//  Created by Nicolás Stefoni on 18/03/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

internal enum FeedbackType: String {
    case list, text
}

internal class AlertFeedbackFlow: JsonParsingProtocol {
    
    static var customFlows: [String: AlertFeedbackFlow] = [:]
    
    public let title: String
    public let type: FeedbackType
    public let options: [AlertFeedbackStep]
    public let tag: String?
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        title = json["titleText"].stringValue
        type = FeedbackType(rawValue: json["type"].stringValue) ?? .list
        
        options = AlertFeedbackStep.array(json["options"].arrayObject).sorted { (step1, step2) -> Bool in
            return step1.sortOrder < step2.sortOrder
        }
        
        tag = json["tag"].string
    }
    
    public class func customFlows(_ customFlowDicts: [String: JSON]) {
        for key in customFlowDicts.keys {
            if let customFlowDict = customFlowDicts[key], let customFlow = AlertFeedbackFlow(customFlowDict.dictionaryObject as AnyObject) {
                customFlows[key] = customFlow
            }
        }
    }
    
}
