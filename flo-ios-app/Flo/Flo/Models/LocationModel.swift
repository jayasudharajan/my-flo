//
//  LocationModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 05/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum SystemMode: String {
    case home, away, sleep
}

internal class LocationModel: JsonParsingProtocol {
    
    public let id: String
    public let city: String
    public let postalCode: String
    public let address: String
    public let address2: String?
    public let country: String
    public let state: String
    public let timezone: String
    public var nickname: String
    public let occupants: Int
    public var devices: [DeviceModel]
    public let plumbingType: String
    public let gallonsPerDayGoal: Double
    public let waterShutoffKnown: String
    public let isProfileComplete: Bool
    public let indoorAmenities: [String]
    public let outdoorAmenities: [String]
    public let locationSize: String
    public let locationType: String
    public let residenceType: String
    public let stories: Int
    public let showerBathCount: Int
    public let toiletCount: Int
    public let waterSource: String
    public let plumbingAppliances: [String]
    public let waterUtility: String?
    public let homeownersInsurance: String?
    public let hasPastWaterDamage: Bool
    public let pastWaterDamageClaimAmount: String?
    
    public var systemMode: SystemMode
    public var systemModeLocked: Bool
    public let floProtect: Bool
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let id = json["id"].string,
            let city = json["city"].string,
            let postalCode = json["postalCode"].string,
            let address = json["address"].string,
            let country = json["country"].string,
            let state = json["state"].string,
            let timezone = json["timezone"].string,
            let occupants = json["occupants"].int,
            let gallonsPerDayGoal = json["gallonsPerDayGoal"].double,
            let waterShutoffKnown = json["waterShutoffKnown"].string,
            let indoorAmenities = (json["indoorAmenities"].arrayObject ?? []) as? [String],
            let outdoorAmenities = (json["outdoorAmenities"].arrayObject ?? []) as? [String],
            let locationSize = json["locationSize"].string,
            let plumbingAppliances = (json["plumbingAppliances"].arrayObject ?? []) as? [String]
        else {
            LoggerHelper.log("Error parsing LocationModel", level: .error)
            return nil
        }
        
        plumbingType = json["plumbingType"].string ?? "galvanized"
        isProfileComplete = json["isProfileComplete"].bool ?? false
        locationType = json["locationType"].stringValue
        residenceType = json["residenceType"].stringValue
        stories = json["stories"].intValue
        self.address2 = json["address2"].string
        
        let modeDict = json["systemMode"].dictionaryValue
        let systemModeKey = modeDict["target"]?.string ?? (modeDict["lastKnown"]?.string ?? "sleep")
        systemMode = SystemMode(rawValue: systemModeKey) ?? .sleep
        systemModeLocked = modeDict["isLocked"]?.boolValue ?? true
        
        let nick = json["nickname"].stringValue
        self.nickname =  !nick.isEmpty ? nick : address
        self.floProtect = json["subscription"].dictionaryValue["isActive"]?.bool ?? false
        devices = DeviceModel.array(json["devices"].arrayObject).sorted(by: { (d1, d2) -> Bool in
            d1.nickname < d2.nickname
        })
        
        self.waterUtility = json["waterUtility"].string
        self.homeownersInsurance = json["homeownersInsurance"].string
        self.pastWaterDamageClaimAmount = json["pastWaterDamageClaimAmount"].string
        self.showerBathCount = json["showerBathCount"].int ?? 0
        self.toiletCount = json["toiletCount"].int ?? 0
        self.hasPastWaterDamage = json["hasPastWaterDamage"].bool ?? false
        self.waterSource = json["waterSource"].string ?? ""
        
        self.id = id
        self.city = city
        self.postalCode = postalCode
        self.address = address
        self.country = country
        self.state = state
        self.timezone = timezone
        self.occupants = occupants
        self.gallonsPerDayGoal = gallonsPerDayGoal
        self.waterShutoffKnown = waterShutoffKnown
        self.indoorAmenities = indoorAmenities
        self.outdoorAmenities = outdoorAmenities
        self.locationSize = locationSize
        self.plumbingAppliances = plumbingAppliances
    }
    
    init(_ builder: AddLocationBuilder) {
        self.plumbingType = builder.plumbingType ?? ""
        self.locationType = builder.locationType ?? ""
        self.residenceType = builder.residenceType ?? ""
        self.stories = builder.stories ?? 1
        self.address2 = builder.address2 ?? ""
        self.nickname = builder.nickname ?? (builder.address ?? "")
        self.waterUtility = builder.waterUtility ?? ""
        self.homeownersInsurance = builder.homeownersInsurance ?? ""
        self.pastWaterDamageClaimAmount = builder.pastWaterDamageClaimAmount ?? ""
        self.toiletCount = Int(builder.toiletCount ?? 1)
        self.hasPastWaterDamage = builder.hasPastWaterDamage ?? false
        self.waterSource = builder.waterSource ?? ""
        self.city = builder.city ?? ""
        self.postalCode = builder.postalCode ?? ""
        self.address = builder.address ?? ""
        self.country = builder.selectedCountry?.id ?? ""
        self.state = (builder.selectedState?.id.lowercased() ?? builder.freeTextState) ?? ""
        self.timezone = builder.selectedTimezone?.id ?? ""
        self.occupants = builder.occupants ?? 1
        self.gallonsPerDayGoal = builder.gallonsPerDayGoal ?? 0
        self.waterShutoffKnown = builder.waterShutoffKnown ?? ""
        self.indoorAmenities = builder.indoorAmenities
        self.outdoorAmenities = builder.outdoorAmenities
        self.locationSize = builder.locationSize ?? ""
        self.plumbingAppliances = builder.plumbingAppliances
        
        self.id = builder.id ?? ""
        self.devices = (builder.devices ?? []).sorted(by: { (d1, d2) -> Bool in
            d1.nickname < d2.nickname
        })
        self.isProfileComplete = builder.isProfileComplete ?? true
        self.showerBathCount = builder.showerBathCount ?? 0
        self.systemMode = builder.systemMode ?? .home
        self.systemModeLocked = builder.systemModeLocked ?? false
        self.floProtect = builder.floProtect ?? false
    }
    
    public class func array(_ objects: [Any]?) -> [LocationModel] {
        var locations: [LocationModel] = []
        
        for object in objects ?? [] {
            if let location = LocationModel(object as AnyObject) {
                locations.append(location)
            }
        }
        
        return locations
    }
    
    public func setNickname(_ nickname: String) {
        self.nickname = nickname
    }
}
