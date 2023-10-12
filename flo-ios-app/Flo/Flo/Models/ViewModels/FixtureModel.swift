//
//  FixtureModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 19/12/17.
//  Copyright © 2017 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum FixtureType: String {
    
    case shower = "shower/bath", toilet, appliance, faucet, other, irrigation, pool
    
    public var name: String {
        return rawValue.capitalized
    }
    
    public var color: UIColor {
        switch self {
        case .shower:
            return UIColor(hex: "EC3824")
        case .toilet:
            return UIColor(hex: "F4A73B")
        case .appliance:
            return UIColor(hex: "01B6CD")
        case .faucet:
            return UIColor(hex: "A43DB6")
        case .other:
            return UIColor(hex: "9DBED1")
        case .irrigation:
            return UIColor(hex: "4B84BD")
        case .pool:
            return UIColor(hex: "1EF1CF")
        }
    }
    
    public var image: UIImage? {
        return UIImage(named: rawValue.replacingOccurrences(of: "/", with: "_"))?.withRenderingMode(.alwaysTemplate)
    }
}

internal class FixtureModel: JsonParsingProtocol {
    
    public var consumption: Double
    public let type: FixtureType
    public var ratio: Double
    public let eventsAmount: Int
    public let position: Int
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let gallons = json["gallons"].double,
            let typeKey = json["name"].string,
            let ratio = json["ratio"].double,
            let eventsAmount = json["numEvents"].int,
            let position = json["index"].int
        else { return nil }
        
        self.consumption = MeasuresHelper.adjust(gallons, ofType: .volume)
        self.type = FixtureType(rawValue: typeKey) ?? .other
        self.ratio = ratio
        self.eventsAmount = eventsAmount
        self.position = position
    }
    
    init(gallons: Double, type: FixtureType) {
        self.consumption = MeasuresHelper.adjust(gallons, ofType: .volume)
        self.type = type
        self.ratio = 0
        eventsAmount = 0
        position = 0
    }
    
    public class func array(_ objects: [Any]?) -> [FixtureModel] {
        var fixtures: [FixtureModel] = []
        
        for object in objects ?? [] {
            if let fixture = FixtureModel(object as AnyObject) {
                fixtures.append(fixture)
            }
        }
        
        return fixtures
    }
    
}
