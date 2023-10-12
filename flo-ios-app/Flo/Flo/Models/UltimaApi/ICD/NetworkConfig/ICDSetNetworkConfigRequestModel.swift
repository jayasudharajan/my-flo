//
//  ICDSetNetworkConfigRequestModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/26/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

 internal class ICDSetNetworkConfigRequestModel: ICDBaseModel, Mappable {
    
    public var params: NetworkConfigModel?
    
    init(config: NetworkConfigModel) {
        super.init()
        
        method = "set_wifi_sta_config"
        params = config
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        id <- map["id"]
        params <- map["params"]
        method <- map["method"]
    }
    
}
