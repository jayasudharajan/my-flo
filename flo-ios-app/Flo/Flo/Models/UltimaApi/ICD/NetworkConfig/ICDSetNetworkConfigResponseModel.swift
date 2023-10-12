//
//  ICDSetNetworkConfigResponseModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/25/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation

import ObjectMapper

final internal class ICDSetNetworkConfigResponseModel: ICDAPIResponseModel<Bool, AnyObject>, Mappable {
    
    override init() {
        super.init()
        method = "set_wifi_sta_config"
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        id <- map["id"]
        result <- map["result"]
    }
    
}
