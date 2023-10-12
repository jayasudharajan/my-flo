//
//  FloGatewayCommands.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/16/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation

internal class FloICDService {
    
    class var gatewayJsonFormatVersion: String {
        if let jsf = PlistHelper.valueForKey("ICDJsonFormatVersion") as? String {
            return jsf
        } else {
            return "2.0"
        }
    }
    
    class var ICDPairingVersion: Int {
        if let pv = PlistHelper.valueForKey("ICDPairingVersion") as? Int {
            return pv
        } else {
            return 1
        }
    }
}
