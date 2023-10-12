//
//  MeasuresHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 9/8/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

internal enum MeasureSystem: String {
    case imperial = "imperial_us", metricKpa = "metric_kpa", metricBar = "metric_bar"
}

internal enum MeasureType: Int {
    case volume = 0, temperature = 1, pressure = 2, flow = 3, area = 4
}

internal class MeasuresHelper {
    
    public static let kMeasuresSystemKey = "measure_system"
    public static var measureSystems: [MeasureSystem] = []
    
    private static let measuresUnits = [
        MeasureSystem.imperial: ["gallons", "ºF", "PSI", "gpm", "square_feet"],
        MeasureSystem.metricKpa: ["liters", "ºC", "kPa", "lpm", "square_meters"],
        MeasureSystem.metricBar: ["liters", "ºC", "Bar", "lpm", "square_meters"]
    ]
    
    private static let unitsAbbreviations = [
        MeasureSystem.imperial: ["gal", "ºF", "PSI", "gpm", "ft²"],
        MeasureSystem.metricKpa: ["L", "ºC", "kPa", "lpm", "m²"],
        MeasureSystem.metricBar: ["L", "ºC", "Bar", "lpm", "m²"]
    ]
    
    public class func unitName(for type: MeasureType, measureSystem: MeasureSystem? = nil) -> String {
        let system = measureSystem ?? getMeasureSystem()
        
        return measuresUnits[system]![type.rawValue].localized
    }
    
    public class func unitAbbreviation(for type: MeasureType, measureSystem: MeasureSystem? = nil) -> String {
        let system = measureSystem ?? getMeasureSystem()
        
        return unitsAbbreviations[system]![type.rawValue]
    }
    
    public class func getMeasureSystem() -> MeasureSystem {
        return MeasureSystem(rawValue: UserDefaults.standard.string(forKey: kMeasuresSystemKey) ?? "") ?? .imperial
    }
    
    public class func setMeasureSystem(_ system: MeasureSystem) {
        UserDefaults.standard.set(system.rawValue, forKey: kMeasuresSystemKey)
    }
    
    public class func adjust(
        _ value: Double,
        ofType type: MeasureType,
        from baseSystem: MeasureSystem = .imperial,
        to system: MeasureSystem? = nil
    ) -> Double {
        let toSystem = system ?? getMeasureSystem()
        
        switch baseSystem {
        case .imperial:
            switch toSystem {
            case .imperial:
                return value
            case .metricKpa:
                switch type {
                case .volume:
                    return value * 3.78541
                case .temperature:
                    return (value - 32) / 1.8
                case .pressure:
                    return value * 6.89476
                case .flow:
                    return value * 3.78541
                case.area:
                    return value / 10.764
                }
            case .metricBar:
                switch type {
                case .volume:
                    return value * 3.78541
                case .temperature:
                    return (value - 32) / 1.8
                case .pressure:
                    return value * 0.06894
                case .flow:
                    return value * 3.78541
                case.area:
                    return value / 10.764
                }
            }
        case .metricKpa:
            switch toSystem {
            case .imperial:
                switch type {
                case .volume:
                    return value / 3.78541
                case .temperature:
                    return (value * 1.8) + 32
                case .pressure:
                    return value / 6.89476
                case .flow:
                    return value / 3.78541
                case.area:
                    return value * 10.764
                }
            case .metricKpa:
                return value
            case .metricBar:
                switch type {
                case .volume:
                    return value
                case .temperature:
                    return value
                case .pressure:
                    return value * 0.01
                case .flow:
                    return value
                case .area:
                    return value
                }
            }
        case .metricBar:
            switch toSystem {
            case .imperial:
                switch type {
                case .volume:
                    return value / 3.78541
                case .temperature:
                    return (value * 1.8) + 32
                case .pressure:
                    return value / 0.06894
                case .flow:
                    return value / 3.78541
                case.area:
                    return value * 10.764
                }
            case .metricKpa:
                return value
            case .metricBar:
                switch type {
                case .volume:
                    return value
                case .temperature:
                    return value
                case .pressure:
                    return value / 0.01
                case .flow:
                    return value
                case .area:
                    return value
                }
            }
        }
    }
    
}

internal class Threshold {
    
    fileprivate let _min: [String: Int]
    public var min: Int {
        return _min[MeasuresHelper.getMeasureSystem().rawValue] ?? 0
    }
    
    fileprivate var _max: [String: Int]
    public var max: Int {
        return _max[MeasuresHelper.getMeasureSystem().rawValue] ?? 1
    }
    
    public let measureType: MeasureType
    
    init(dict: [String: JSON], measureType: MeasureType) {
        switch measureType {
        case .flow:
            let gpmDict = dict["gpm"]?.dictionaryValue ?? [:]
            let gpmMin = gpmDict["minValue"]?.intValue ?? 0
            let gpmMax = gpmDict["maxValue"]?.intValue ?? 1
            
            let lpmDict = dict["lpm"]?.dictionaryValue ?? [:]
            let lpmMin = lpmDict["minValue"]?.intValue ?? 0
            let lpmMax = lpmDict["maxValue"]?.intValue ?? 1
            
            _min = [
                MeasureSystem.imperial.rawValue: gpmMin,
                MeasureSystem.metricKpa.rawValue: lpmMin
            ]
            _max = [
                MeasureSystem.imperial.rawValue: gpmMax,
                MeasureSystem.metricKpa.rawValue: lpmMax
            ]
        case .temperature:
            let tempFDict = dict["tempF"]?.dictionary ?? [:]
            let tempFMin = tempFDict["minValue"]?.intValue ?? 0
            let tempFMax = tempFDict["maxValue"]?.intValue ?? 1
            
            let tempCDict = dict["tempC"]?.dictionary ?? [:]
            let tempCMin = tempCDict["minValue"]?.intValue ?? 0
            let tempCMax = tempCDict["maxValue"]?.intValue ?? 1
            
            _min = [
                MeasureSystem.imperial.rawValue: tempFMin,
                MeasureSystem.metricKpa.rawValue: tempCMin
            ]
            _max = [
                MeasureSystem.imperial.rawValue: tempFMax,
                MeasureSystem.metricKpa.rawValue: tempCMax
            ]
        default:
            let psiDict = dict["psi"]?.dictionary ?? [:]
            let psiMin = psiDict["minValue"]?.intValue ?? 0
            let psiMax = psiDict["maxValue"]?.intValue ?? 1
            
            let kPaDict = dict["kPa"]?.dictionary ?? [:]
            let kPaMin = kPaDict["minValue"]?.intValue ?? 0
            let kPaMax = kPaDict["maxValue"]?.intValue ?? 1
            
            _min = [
                MeasureSystem.imperial.rawValue: psiMin,
                MeasureSystem.metricKpa.rawValue: kPaMin
            ]
            _max = [
                MeasureSystem.imperial.rawValue: psiMax,
                MeasureSystem.metricKpa.rawValue: kPaMax
            ]
        }
        
        self.measureType = measureType
    }
    
}
