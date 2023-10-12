//
//  UserTokenModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/8/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

class UserTokenModel: Mappable {
    
    var token: String?
    var deviceType: String = "ios"
    
    init(token: String) {
        self.token = token
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        token <- map["token"]
        deviceType <- map["deviceType"]
    }
    
    var userToken: [String: AnyObject]? {
        if token != nil {
            return self.toJSON() as [String: AnyObject]?
        }
        
        return nil
    }

}
