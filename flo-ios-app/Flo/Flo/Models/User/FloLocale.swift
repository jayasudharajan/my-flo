//
//  FloLocale.swift
//  Flo
//
//  Created by Nicolás Stefoni on 6/25/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

public class FloLocale: JsonParsingProtocol {
    
    public let id: String
    public let name: String
    public let shortName: String
    public var regions: [LocaleRegion] = []
    public var timezones: [LocaleTimezone] = []
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let id = json["key"].string,
            let name = json["longDisplay"].string,
            let shortName = json["shortDisplay"].string
        else { return nil }
        
        let regionsArray = json["regions"].arrayObject
        let timezonesArray = json["timezones"].arrayObject
        
        if regionsArray != nil && !regionsArray!.isEmpty {
            regions = LocaleRegion.array(regionsArray)
        }
        
        if timezonesArray != nil && !timezonesArray!.isEmpty {
            timezones = LocaleTimezone.array(timezonesArray)
        }
        
        self.id = id
        self.name = name
        self.shortName = shortName
    }
    
    public class func array(_ objects: [Any]?) -> [FloLocale] {
        var locales: [FloLocale] = []
        
        for object in objects ?? [] {
            if let dictionary = object as? NSDictionary, let countriesList = dictionary["country"] as? [NSDictionary] {
                for countryDict in countriesList {
                    let countryDictMutable = NSMutableDictionary(dictionary: countryDict)
                    
                    if let countryKey = countryDict["key"] as? String {
                        for o in objects ?? [] {
                            if let d = o as? NSDictionary {
                                if let regions = d["region_" + countryKey] {
                                    countryDictMutable["regions"] = regions
                                } else if let timezones = d["timezone_" + countryKey] {
                                    countryDictMutable["timezones"] = timezones
                                }
                            }
                        }
                    }
                    
                    if let locale = FloLocale(countryDictMutable as AnyObject) {
                        locales.append(locale)
                    }
                }
                break
            }
        }
        
        return locales
    }
    
    public class func compareTwoLocales(_ locale1: FloLocale, _ locale2: FloLocale) -> Bool {
        if locale1.id.lowercased() == "us" {
            return true
        }
        if locale2.id.lowercased() == "us" {
            return false
        }
        if locale1.id.lowercased() == "ca" {
            return true
        }
        if locale2.id.lowercased() == "ca" {
            return false
        }
        
        return locale1.name < locale2.name
    }

}

public class LocaleRegion: JsonParsingProtocol {
    
    public let id: String
    public let name: String
    public let shortName: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let id = json["key"].string,
            let name = json["longDisplay"].string,
            let shortName = json["shortDisplay"].string
        else { return nil }
        
        self.id = id
        self.name = name
        self.shortName = shortName
    }
    
    public class func array(_ objects: [Any]?) -> [LocaleRegion] {
        var regions: [LocaleRegion] = []
        
        for object in objects ?? [] {
            if let region = LocaleRegion(object as AnyObject) {
                regions.append(region)
            }
        }
        
        return regions
    }
    
}

public class LocaleTimezone: JsonParsingProtocol {
    
    public let id: String
    public let name: String
    public let shortName: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let id = json["key"].string,
            let name = json["longDisplay"].string,
            let shortName = json["shortDisplay"].string
            else { return nil }
        
        self.id = id
        self.name = name
        self.shortName = shortName
    }
    
    public class func array(_ objects: [Any]?) -> [LocaleTimezone] {
        var timezones: [LocaleTimezone] = []
        
        for object in objects ?? [] {
            if let timezone = LocaleTimezone(object as AnyObject) {
                timezones.append(timezone)
            }
        }
        
        return timezones
    }
    
}
