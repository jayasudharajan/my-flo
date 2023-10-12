//
//  NetworkConfigModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 6/20/19.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class NetworkConfigModel: Mappable {
    
    public var wifiClientSsid: String?
    public var wifiClientPassword: String?
    public var wifiStaEnabled = "1" // It's always on 1 for now
    public var wifiEncryption: String?
    
    required init?(map: Map) {}
    
    init(_ clientWiFi: WiFiModel) {
        wifiClientSsid = clientWiFi.ssid
        wifiClientPassword = clientWiFi.password
        wifiEncryption = clientWiFi.encryption
    }
    
    func mapping(map: Map) {
        wifiClientSsid <- map["wifi_sta_ssid"]
        wifiClientPassword <- map["wifi_sta_password"]
        wifiStaEnabled <- map["wifi_sta_enabled"]
        wifiEncryption <- map["wifi_sta_encryption"]
    }
    
}
