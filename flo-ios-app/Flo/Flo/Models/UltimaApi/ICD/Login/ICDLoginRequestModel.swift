//
//  Login.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

final internal class ICDLoginRequestModel: ICDBaseModel, Mappable {
    
    var params: LoginParamModel?

    init(token: String) {
        super.init()
        
        method = "login"
        params = LoginParamModel(token: token)
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        params <- map["params"]
        id <- map["id"]
        method <- map["method"]
    }
    
}
