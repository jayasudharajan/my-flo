//
//  LoginParam.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

final internal class LoginParamModel: Mappable {
    public var token: String?
    
    init(token: String) {
        self.token = token
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        token <- map["token"]
    }
}
