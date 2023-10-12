//
//  Appliances.swift
//  Flo
//
//  Created by Matias Paillet on 10/17/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal class Appliances: JsonParsingProtocol {
    
    public var indoor: [BaseListModel] = []
    public var outdoors: [BaseListModel] = []
    public var appliances: [BaseListModel] = []
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [NSDictionary] ?? []).arrayValue
        
        for a in json {
            let item = a.dictionaryValue
            if let indoorList = item["fixture_indoor"]?.array {
                for item in indoorList {
                    if let object = BaseListModel(item.dictionaryValue as AnyObject) {
                        self.indoor.append(object)
                    }
                }
            } else if let outdoorsList = item["fixture_outdoor"]?.array {
                for item in outdoorsList {
                    if let object = BaseListModel(item.dictionaryValue as AnyObject) {
                        self.outdoors.append(object)
                    }
                }
            } else if let appliancesList = item["home_appliance"]?.array {
                for item in appliancesList {
                    if let object = BaseListModel(item.dictionaryValue as AnyObject) {
                        self.appliances.append(object)
                    }
                }
            }
        }
    }
}
