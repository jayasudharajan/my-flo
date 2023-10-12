//
//  AlertResolutionAction.swift
//  Flo
//
//  Created by Nicolás Stefoni on 09/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

internal class AlertResolutionAction: JsonParsingProtocol {
    
    public let id: Int
    public let text: String
    public let snoozeSeconds: Int
    public let sortOrder: Int
    public let displayOnStatus: Int
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        id = json["id"].intValue
        text = json["text"].stringValue
        snoozeSeconds = json["snoozeSeconds"].intValue
        sortOrder = json["sort"].intValue
        displayOnStatus = json["displayOnStatus"].intValue
    }
    
    public class func array(_ objects: [Any]?) -> [AlertResolutionAction] {
        var alertResolutionActions: [AlertResolutionAction] = []
        
        for object in objects ?? [] {
            if let alertResolutionAction = AlertResolutionAction(object as AnyObject) {
                alertResolutionActions.append(alertResolutionAction)
            }
        }
        
        return alertResolutionActions
    }
    
}
