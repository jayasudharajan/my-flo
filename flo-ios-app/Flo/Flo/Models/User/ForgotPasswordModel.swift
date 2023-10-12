//
//  ForgotPasswordModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/15/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class ForgotPasswordModel: Mappable {
    
    var email: String?
    
    init(email: String) {
        self.email = email
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        email <- map["email"]
    }
    
    func jsonify() -> [String: AnyObject]? {
        return self.toJSON() as [String: AnyObject]?
    }
}
