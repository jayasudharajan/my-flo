//
//  FixturesComputationModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 13/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum ComputationStatus: String {
    case executed, learning, noUsage, notSubscribed
}

internal enum ConsumptionRange: Int {
   case daily = 0, weekly, monthly
}

internal class FixturesComputationModel: JsonParsingProtocol {
    
    public let id: String
    public let range: ConsumptionRange
    public var fixtures: [FixtureModel]
    public var status: ComputationStatus
    public var date: Date
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let id = json["id"].string,
            let rangeValue = json["duration"].string,
            let fixturesArray = json["fixtures"].arrayObject,
            let statusValue = json["status"].string,
            let dateString = json["computeEndDate"].string,
            let date = Date.iso8601ToDate(dateString)
        else { return nil }
        
        self.id = id
        self.fixtures = FixtureModel.array(fixturesArray)
        self.status = ComputationStatus(rawValue: statusValue) ?? .learning
        self.date = date
        
        if json["isStale"].boolValue {
            self.status = .noUsage
        }
        
        if rangeValue == "24h" {
            range = .daily
            if date.timeIntervalSinceNow > 86400 {
                self.status = .noUsage
            }
        } else {
            range = .weekly
            if date.timeIntervalSinceNow > 604800 {
                self.status = .noUsage
            }
        }
    }
    
    init(range: ConsumptionRange, status: ComputationStatus) {
        id = "\(range.rawValue)"
        self.range = range
        fixtures = [
            FixtureModel(gallons: 0, type: .toilet),
            FixtureModel(gallons: 0, type: .shower),
            FixtureModel(gallons: 0, type: .faucet),
            FixtureModel(gallons: 0, type: .appliance),
            FixtureModel(gallons: 0, type: .pool),
            FixtureModel(gallons: 0, type: .irrigation),
            FixtureModel(gallons: 0, type: .other)
        ]
        self.status = status
        date = Date()
    }
    
}
