//
//  ICDCertUploadRequestModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/26/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class ICDCertUploadRequestModel: ICDBaseModel, Mappable {
    
    var params: ICDSetCertModel?
    
    init(params: ICDSetCertModel) {
        super.init()
        method = "set_certificates"
        self.params = params
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        jsonRPC <- map["jsonrpc"]
        id <- map["id"]
        method <- map["method"]
        params <- map["params"]
    }
    
}
