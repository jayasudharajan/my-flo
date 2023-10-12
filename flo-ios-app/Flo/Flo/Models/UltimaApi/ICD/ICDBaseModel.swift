//
//  FloGatewayBaseApiRequest.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class ICDBaseModel {
    public var jsonRPC: String?
    public var id: Int?
    public var method: String?
    
    init() {
        jsonRPC = FloICDService.gatewayJsonFormatVersion
        id = FloICDService.ICDPairingVersion
        
    }
}
