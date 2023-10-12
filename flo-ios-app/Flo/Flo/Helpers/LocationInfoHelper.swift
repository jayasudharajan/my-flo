//
//  LocationInfoHelper.swift
//  Flo
//
//  Created by Josefina Perez on 11/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class LocationInfoHelper {
    
    public static let kOccupantsMin = 1
    public static let kOccupantsMax = 20
    public static var countries: [FloLocale] = []
    public static var states: [LocaleRegion] = []
    public static var timezones: [LocaleTimezone] = []

    fileprivate static let homeTypes = [
    HomeType(identifier: "sfh"), HomeType(identifier: "condo"), HomeType(identifier: "apartment"), HomeType(identifier: "other")]
    
    fileprivate static let locationSizes = [
        LocationSize(identifier: "lte_700"), LocationSize(identifier: "gt_700_ft_lte_1000_ft"), LocationSize(identifier: "gt_1000_ft_lte_2000_ft"), LocationSize(identifier: "gt_2000_ft_lte_4000_ft"),
        LocationSize(identifier: "gt_4000_ft")]
    
    fileprivate static let numberOfFloors: [LocationStory] = [
    LocationStory(numberOfFloors: 1), LocationStory(numberOfFloors: 2), LocationStory(numberOfFloors: 3),
    LocationStory(numberOfFloors: 4)]
    
    fileprivate static let sourcesOfWater = [WaterSource(identifier: "utility"), WaterSource(identifier: "well")]
    
    public class func getHomeTypes() -> [HomeType] {
        return homeTypes
    }
    
    public class func getLocationSizes() -> [LocationSize] {
        return locationSizes
    }
    
    public class func getNumberOfFloors() -> [LocationStory] {
        return numberOfFloors
    }
    
    public class func getSourcesOfWater() -> [WaterSource] {
        return sourcesOfWater
    }
}

internal struct LocationStory {
    var displayName: String
    var numberOfFloors: Int
    
    init(numberOfFloors: Int) {
        
        self.numberOfFloors = numberOfFloors
        
        switch numberOfFloors {
        case 1:
            displayName = "1"
        case 2:
            displayName = "2"
        case 3:
            displayName = "3"
        case _ where numberOfFloors >= 4:
            displayName = "4+"
        default:
            displayName = ""
        }
    }
}

internal struct HomeType {
    var displayName: String
    var backendIdentifier: String
    
    init(identifier: String) {
        
        self.backendIdentifier = identifier
        
        switch identifier {
        case "sfh":
            displayName = "single_family_house".localized
        case "condo":
            displayName = "condo".localized
        case "apartment":
            displayName = "apartment".localized
        case "other":
            displayName = "other_".localized
        default:
            displayName = ""
        }
    }
}

internal struct TypeOfPlumbing {
    var displayName: String
    var backendIdentifier: String
    
    init(identifier: String) {
        
        self.backendIdentifier = identifier
        
        switch identifier {
        case "copper":
            displayName = "copper".localized
        case "galvanized":
            displayName = "galvanized".localized
        case "unsure":
            displayName = "not_sure".localized
        default:
            displayName = ""
        }
    }
}

internal struct WaterSource {
    var displayName: String
    var backendIdentifier: String
    
    init(identifier: String) {
        
        self.backendIdentifier = identifier
        
        switch identifier {
        case "utility":
            displayName = "city_water".localized
        case "well":
            displayName = "well".localized
        default:
            displayName = ""
        }
    }
}

internal struct LocationSize {
    var displayName: String
    var backendIdentifier: String
    
    init(identifier: String) {
        
        self.backendIdentifier = identifier
        
        let isImperial = MeasuresHelper.getMeasureSystem() == .imperial
        switch identifier {
        case "lte_700":
            displayName = String(format: "less_than_number".localized, isImperial ? 700 : 70)
        case "gt_700_ft_lte_1000_ft":
            displayName = String(format: "range".localized, isImperial ? 700 : 70, isImperial ? 1000 : 100)
        case "gt_1000_ft_lte_2000_ft":
            displayName = String(format: "range".localized, isImperial ? 1001 : 101, isImperial ? 2000 : 200)
        case "gt_2000_ft_lte_4000_ft":
            displayName = String(format: "range".localized, isImperial ? 2001 : 201, isImperial ? 4000 : 400)
        case "gt_4000_ft":
            displayName = String(format: "more_than_number".localized, isImperial ? 4000 : 400)
        default:
            displayName = ""
        }
    }
    
    public func getSizeWithUnit() -> String {
        return displayName + " \(MeasuresHelper.unitName(for: .area))"
    }
}
