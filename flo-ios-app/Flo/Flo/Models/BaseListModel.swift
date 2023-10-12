//
//  BaseListModel.swift
//  Flo
//
//  Created by Matias Paillet on 10/8/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal class BaseListModel: JsonParsingProtocol {
    
    public let id: String
    public let name: String
    public let shortName: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let id = json["key"].string,
            let name = json["longDisplay"].string,
            let shortName = json["shortDisplay"].string
            else { return nil }
        
        self.id = id
        self.name = name
        self.shortName = shortName
    }
}
