//
//  FloICDPurchaseRequestModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/26/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class FloICDPurchaseResponseModel: Mappable {
    
    public var deviceId: String?
    public var apName: String?
    public var apPassword: String?
    public var icdLoginToken: String?
    public var serverCert: String?
    public var clientCert: String?
    public var clientKey: String?
    public var webSocketCert: String?
    public var icdDataId: String?
    
    init() { }
    required init?(map: Map) {}
    
    public func mapping(map: Map) {
        deviceId <- map["did"]
        apName <- map["apName"]
        apPassword <- map["apPassword"]
        icdLoginToken <- map["icdLoginToken"]
        serverCert <- map["serverCert"]
        clientCert <- map["clientCert"]
        clientKey <- map["clientKey"]
        webSocketCert <- map["webSocketCert"]
    }
    
}
