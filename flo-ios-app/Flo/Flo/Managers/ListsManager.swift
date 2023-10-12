//
//  ListsManager.swift
//  Flo
//
//  Created by Matias Paillet on 10/4/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal enum ListType: String {
    case irrigationTypes = "/irrigation_type"
    case prvInstallationTypes = "/prv"
    case deviceMakes = "/device_make"
    case pipeTypes = "/pipe_type"
    case residenceTypes = "/residence_type"
    case appliances = "?id=fixture_indoor,fixture_outdoor,home_appliance"
    
//    public func getMappingClass() -> AnyClass {
//        switch self {
//        case .irrigationTypes:
//            return IrrigationType.self
//        }
//    }
}

internal class ListsManager {
    
    fileprivate var cache: [String: [JsonParsingProtocol]] = [:]
    
    public class var shared: ListsManager {
        struct Static {
            static let instance = ListsManager()
        }
        return Static.instance
    }
    
    // MARK: Public Methods
    
    public func getIrrigationTypes(
        _ callback: @escaping (FloRequestErrorModel?, [IrrigationType]) -> Void) -> [IrrigationType] {
        return getList(list: .irrigationTypes, callback)
    }
    
    public func getPRVInstallationTypes(
        _ callback: @escaping (FloRequestErrorModel?, [PRVInstallationType]) -> Void) -> [PRVInstallationType] {
        return getList(list: .prvInstallationTypes, callback)
    }
    
    public func getPipeTypes(
        _ callback: @escaping (FloRequestErrorModel?, [PipeType]) -> Void) -> [PipeType] {
        return getList(list: .pipeTypes, callback)
    }
    
    public func getResidenceTypes(
        _ callback: @escaping (FloRequestErrorModel?, [ResidenceType]) -> Void) -> [ResidenceType] {
        return getList(list: .residenceTypes, callback)
    }
    
    public func getAppliances(
        _ callback: @escaping (FloRequestErrorModel?, [Appliances]) -> Void) -> [Appliances] {
        return getList(list: .appliances, callback)
    }
    
//    public func getDeviceMakes(
//        _ callback: @escaping (FloRequestErrorModel?, [DeviceToPair]) -> Void) -> [DeviceToPair] {
//        return getList(list: .deviceMakes, callback)
//    }
    
    // MARK: Private Methods
    
    fileprivate func getList<T: JsonParsingProtocol>(
        list: ListType,
        _ callback: @escaping (FloRequestErrorModel?, [T]) -> Void) -> [T] {
        
        if let cachedValue = cache[list.rawValue], let castedValue = cachedValue as? [T] {
            return castedValue
        } else {
            FloApiRequest(
                controller: "v2/lists" + list.rawValue,
                method: .get,
                queryString: nil,
                data: nil,
                done: { (error, data) in
                    if let e = error {
                        LoggerHelper.log("Error on: GET v2/lists/" + list.rawValue + e.message, level: .error)
                        callback(e, [])
                    } else {
                        if let dict = data as? NSDictionary, let items = dict["items"] as? [NSDictionary] {
                            self.parseResponse(response: items, list: list, callback)
                        } else {
                            LoggerHelper.log("Parsing error on: GET v2/lists/" + list.rawValue, level: .error)
                            callback(nil, [])
                        }
                    }
            }).secureFloRequest()
            
            return []
        }
    }
    
    fileprivate func parseResponse<T: JsonParsingProtocol>(
        response: [NSDictionary],
        list: ListType,
        _ callback: @escaping (FloRequestErrorModel?, [T]) -> Void) {
        
        var types: [T] = []
        
        // Handle special parsing options
        switch list {
        case .appliances:
            if let type = T(response as AnyObject) {
                types.append(type)
            }
//        case .deviceMakes:
//            var deviceTypes: [String] = []
//            for item in response {
//                if let type = item["key"] as? String, type != "puck_oem" {
//                    deviceTypes.append(type)
//                }
//            }
//            self.getModels(types: deviceTypes, { (devices) in
//                callback(nil, devices)
//            })
        default:
            for item in response {
                if let type = T(item) {
                    types.append(type)
                }
            }
        }
        
        //save in internal cache
        self.cache[list.rawValue] = types
        callback(nil, types)
    }
}
