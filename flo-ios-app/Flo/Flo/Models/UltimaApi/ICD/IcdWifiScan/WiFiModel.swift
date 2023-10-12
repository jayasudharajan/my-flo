//
//  WiFiModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 6/20/19.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class WiFiModel: NSObject, Mappable {
    
    public var signal = 60
    public var signalLevel = WifiHelper.signalLevel(60)
    public var ssid = ""
    public var encryption = "none"
    public var password = ""
    
    required init?(map: Map) {}
    
    internal func mapping(map: Map) {
        signal <- map["signal"]
        ssid <- map["ssid"]
        encryption <- map["encryption"]
        
        if signal <= 0 {
            signal = 1
        } else if signal > 80 {
            signal = 80
        }
        
        signalLevel = Int((Double(signal * 4) / 80).rounded(.toNearestOrAwayFromZero))
    }
    
    internal init(ssid: String, password: String) {
        self.ssid = ssid
        self.password = password
        encryption = "psk2+ccmp"
    }
    
}
