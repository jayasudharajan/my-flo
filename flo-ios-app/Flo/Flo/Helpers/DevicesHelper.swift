//
//  DevicesHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 24/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class DevicesHelper {
    
    public static var friendlyTypeNames: [String: String] = [:]
    
    // MARK: - Local methods
    public class func getTypeFriendly(_ type: String) -> String {
        if let typeFriendly = friendlyTypeNames[type] {
            return typeFriendly
        }
        
        return type
    }
    
    public class func getOneLocally(_ id: String) -> DeviceModel? {
        let locations = LocationsManager.shared.locations
        
        for location in locations {
            for device in location.devices where device.id == id {
                return device
            }
        }
        
        return nil
    }
    
    public class func updateDeviceLocally(id: String, _ device: DeviceModel?) {
        let locations = LocationsManager.shared.locations
        
        for location in locations {
            for i in 0 ..< location.devices.count where location.devices[i].id == id {
                if let newDevice = device {
                    newDevice.setStatus(location.devices[i])
                    location.devices[i] = newDevice
                } else {
                    _ = location.devices.remove(at: i)
                }
                break
            }
        }
    }
    
    // MARK: - API calls
    public class func delete(id: String, _ callback: @escaping (FloRequestErrorModel?, Bool) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(id)",
            method: .delete,
            queryString: nil,
            data: nil,
            done: { (error, _) in
                if error != nil {
                    callback(error, false)
                } else {
                    updateDeviceLocally(id: id, nil)
                    callback(nil, true)
                }
            }
        ).secureFloRequest()
    }
    
    public class func restart(id: String, _ callback: @escaping (FloRequestErrorModel?, Bool) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(id)/reset",
            method: .post,
            queryString: nil,
            data: ["target": "power" as AnyObject],
            done: { (error, _) in
                if error != nil {
                    LoggerHelper.log("Error on POST v2/devices/\(id)/reset: \(String(describing: error?.message))", level: .error)
                    callback(error, false)
                } else {
                    callback(nil, true)
                }
            }
        ).secureFloRequest()
    }
    
    public class func getTypes(_ callback: @escaping (FloRequestErrorModel?, [DeviceToPair]) -> Void) {
        FloApiRequest(
            controller: "v2/lists/device_make",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                if let e = error {
                    LoggerHelper.log("Error on: GET v2/lists/device_make" + e.message, level: .error)
                    callback(e, [])
                } else {
                    if let dict = data as? NSDictionary, let list = dict["items"] as? [NSDictionary] {
                        var types: [String] = []
                        for item in list {
                            if let type = item["key"] as? String, type != "puck_oem" {
                                types.append(type)
                            }
                        }
                        self.getModels(types: types, { (devices) in
                            callback(nil, devices)
                        })
                    } else {
                        LoggerHelper.log("Parsing error on: GET v2/lists/device_make", level: .error)
                        callback(nil, [])
                    }
                }
            }
        ).secureFloRequest()
    }
    
    fileprivate class func getModels(types: [String], _ callback: @escaping ([DeviceToPair]) -> Void) {
        var modelTypes = ""
        var typeTuples: [(shortDisplay: String, longDisplay: String)] = []
        for type in types {
            let longDisplay = "device_model_" + type
            modelTypes += longDisplay
            typeTuples.append((shortDisplay: type, longDisplay: longDisplay))
            
            if type != types.last ?? "" {
                modelTypes += ","
            }
        }
        let locationId = UserSessionManager.shared.selectedLocationId ?? ""
        
        FloApiRequest(
            controller: "v2/lists",
            method: .get,
            queryString: ["id": modelTypes],
            data: nil,
            done: { (error, data) in
                if let e = error {
                    LoggerHelper.log("Error on: GET v2/lists" + e.message, level: .error)
                    callback([])
                } else if let dict = data as? NSDictionary, let list = dict["items"] as? [NSDictionary] {
                    var devices: [DeviceToPair] = []
                    for item in list {
                        for key in item.allKeys as? [String] ?? [] {
                            let model = key.replacingOccurrences(of: "device_model_", with: "")
                            
                            if let modelsList = item[key] as? [NSDictionary] {
                                for t in modelsList {
                                    if let typeKey = t["key"] as? String, let friendlyTypeName = t["longDisplay"] as? String {
                                        friendlyTypeNames[typeKey] = friendlyTypeName
                                        devices.append(DeviceToPair(model: model, type: typeKey, locationId: locationId))
                                    }
                                }
                            }
                        }
                    }
                    callback(devices)
                } else {
                    LoggerHelper.log("Parsing error on: GET v2/lists: ", level: .error)
                    callback([])
                }
            }
        ).secureFloRequest()
    }
    
    public class func getOne(_ id: String, _ callback: @escaping (FloRequestErrorModel?, DeviceModel?) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(id)",
            method: .get,
            queryString: nil,
            data: nil,
            done: { (error, data) in
                if let e = error {
                    LoggerHelper.log("Error on: GET v2/devices/id: " + e.message, level: .error)
                    callback(e, nil)
                } else {
                    if let device = DeviceModel(data) {
                        DevicesHelper.updateDeviceLocally(id: id, device)
                        callback(nil, device)
                    } else {
                        let device = DevicesHelper.getOneLocally(id)
                        callback(nil, device)
                    }
                }
            }
        ).secureFloRequest()
    }
    
    public class func setValveState(_ state: ValveState, for id: String, _ callback: @escaping (FloRequestErrorModel?, Bool) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(id)",
            method: .post,
            queryString: nil,
            data: state.postData,
            done: { (error, _) in
                if let e = error {
                    LoggerHelper.log("Set valve error on: POST v2/devices/\(id): " + e.message, level: .error)
                    callback(e, false)
                } else {
                    callback(nil, true)
                }
            }
        ).secureFloRequest()
    }
    
    public class func setKeepWaterRunning(for id: String, _ callback: @escaping (FloRequestErrorModel?) -> Void) {
        FloApiRequest(
            controller: "v2/devices/\(id)/fwProperties",
            method: .post,
            queryString: nil,
            data: ["alarm_suppress_until_event_end": true as AnyObject],
            done: { (error, _) in
                if let errorMsg = error?.message {
                    LoggerHelper.log("Set keep water running: POST v2/devices/\(id)/fwProperties: " + errorMsg, level: .error)
                }
                callback(error)
            }
        ).secureFloRequest()
    }
    
}
