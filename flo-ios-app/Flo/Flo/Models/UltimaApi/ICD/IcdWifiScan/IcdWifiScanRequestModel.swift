//
//  IcdWifiScanRequestModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

final internal class IcdWifiScanRequestModel: ICDAPIResponseModel<[WiFiModel], AnyObject>, Mappable {
    
    override init() {
        super.init()
        method = "scan_wifi_ap"
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        id <- map["id"]
        method <- map["method"]
        fromParams <- map["from_params"]
        result <- map["result"]
    }
    
}
