//
//  IcdWifiScanResponseModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

final internal class IcdWifiScanResponseModel: ICDAPIResponseModel<[WiFiModel], AnyObject>, Mappable {
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        fromParams <- map["from_params"]
        id <- map["id"]
        fromMethod <- map["from_method"]
        result <- map["result"]
    }
    
}
