//
//  WifiHelper.swift
//  Flo
//
//  Created by Matias Paillet on 5/22/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

internal final class WifiHelper {
    
    public class func getCurrentSsid() -> String? {
        if let interfaces: CFArray = CNCopySupportedInterfaces() {
            for i in 0 ..< CFArrayGetCount(interfaces) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if let interfaceData = unsafeInterfaceData as? [String: Any] {
                    return interfaceData["SSID"] as? String
                }
            }
        }
        
        return nil
    }
    
    public class func signalLevel(_ signal: Int) -> Int {
        let absSignal = abs(signal) - 30 < 0 ? 0 : Double(abs(signal) - 30)
        var level = 4 - Int((absSignal / 15).rounded(.towardZero))
        if level < 1 { level = 1 }
        
        return level
    }
    
}
