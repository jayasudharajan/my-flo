//
//  HealthTestHelper.swift
//  Flo
//
//  Created by Josefina Perez on 22/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SwiftyJSON

internal enum HealthTestStatus: String {
    case pending
    case running
    case completed
    case canceled
    case timeout
}

internal enum LeakType: Int {
    case interrupted = 0
    case cancelled = -2
    case appValveopen = -3
    case manualOpen = -4
    case flowDetected = -5
    case thermalExpansion = -6
}

struct HealthTestResult {
    var roundId: String
    var status: HealthTestStatus
    var leakType: LeakType
    var startDate: Date
    var endDate: Date
    var testDuration: Int // in seconds
    var leakLossMinGal: Double
    var leakLossMaxGal: Double
    var startPressure: Double
    var endPressure: Double
    var deltaPressure: Double
    var testPassed: Bool
    
    init(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        roundId = json["roundId"].stringValue
        status = HealthTestStatus.init(rawValue: json["status"].stringValue) ?? .completed
        leakType = LeakType.init(rawValue: json["leakType"].intValue) ?? .interrupted
        startDate = json["startDate"].stringValue.toDate(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        endDate = json["endDate"].stringValue.toDate(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        testDuration = endDate.seconds(from: startDate)
        leakLossMinGal = json["leakLossMinGal"].doubleValue
        leakLossMaxGal = json["leakLossMaxGal"].doubleValue
        startPressure = json["startPressure"].doubleValue
        endPressure = json["endPressure"].doubleValue
        deltaPressure = abs(json["deltaPressure"].doubleValue)
        testPassed = status == .completed ? leakLossMinGal == 0 : false
    }
}

internal class HealthTestHelper {
    
    fileprivate static let kRoundIdKey = "roundId_"
    
    public class func runHealthTest(device: DeviceModel, whenFinished: @escaping (FloRequestErrorModel?, HealthTestResult?) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(device.id)/healthTest/run",
            method: .post,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                if error != nil {
                    whenFinished(error, nil)
                } else {
                    let result = HealthTestResult(data)
                    // Save round id to remember that there is a pending test result to display, in case the APP closes.
                    UserDefaults.standard.set(result.roundId, forKey: kRoundIdKey + device.macAddress)
                    whenFinished(nil, result)
                }
            }
        ).secureFloRequest()
    }
    
    public class func getHealthTestStatus(device: DeviceModel, roundId: String? = nil, whenFinished: @escaping (FloRequestErrorModel?, HealthTestResult?) -> Void) {
        var healthTestUrl = "v2/devices/\(device.id)/healthTest"
        if let roundId = roundId ?? UserDefaults.standard.string(forKey: kRoundIdKey + device.macAddress) {
            healthTestUrl += "/" + roundId
        }
        
        FloApiRequest(
            controller: healthTestUrl,
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                whenFinished(error, HealthTestResult(data))
            }
        ).secureFloRequest()
    }
    
    public class func cancelHealthTest(device: DeviceModel, whenFinished:
        @escaping (FloRequestErrorModel?) -> Void) {
        
        DevicesHelper.setValveState(.open, for: device.id) { (error, _) in
           whenFinished(error)
        }
    }
}
