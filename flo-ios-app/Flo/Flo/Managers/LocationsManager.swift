//
//  LocationsManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 05/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class LocationsManager {
    
    // Singleton
    public class var shared: LocationsManager {
        struct Static {
            static let instance = LocationsManager()
        }
        return Static.instance
    }
    
    fileprivate var _locations: [LocationModel] = []
    public var locations: [LocationModel] {
        get {
            var locations = _locations
            
            if let selectedLocationId = UserSessionManager.shared.selectedLocationId {
                for i in 0 ..< locations.count where locations[i].id == selectedLocationId {
                    if i > 0 {
                        let location = locations.remove(at: i)
                        locations.insert(location, at: 0)
                    }
                    break
                }
            }
            
            return locations
        }
        set {
            _locations = newValue
        }
    }
    
    public var selectedLocation: LocationModel? {
        return locations.first
    }
    
    /**
     This calculated variable does NOT return the selected location ID,
     it just returns the first location ID of the retrieved locations.
     Use it when you know you do NOT have a selected location ID on user's session
     */
    public var firstLocationId: String? {
        return _locations.first?.id
    }
    
    // MARK: - Local methods
    public func reset() {
        stopTrackingDevices()
        _locations = []
    }
    
    public func updateLocationLocally(id: String, _ location: LocationModel?) {
        for i in 0 ..< _locations.count where _locations[i].id == id {
            if let newLocation = location {
                // Prefill devices with the last status info known of them
                for device in newLocation.devices {
                    for oldDevice in _locations[i].devices where oldDevice.id == device.id {
                        device.setStatus(oldDevice)
                        break
                    }
                }
                _locations[i] = newLocation
            } else {
                _ = _locations.remove(at: i)
                
                if UserSessionManager.shared.selectedLocationId == id {
                    UserSessionManager.shared.selectedLocationId = nil
                }
            }
            break
        }
    }
    
    fileprivate func updateDeviceStatus(_ status: DeviceStatus) -> DeviceModel? {
        for l in 0 ..< _locations.count {
            for d in 0 ..< _locations[l].devices.count where _locations[l].devices[d].macAddress == status.macAddress {
                _locations[l].devices[d].setStatus(status)
                return _locations[l].devices[d]
            }
        }
        
        return nil
    }
    
    public func getOneLocally(_ id: String) -> LocationModel? {
        for location in _locations where location.id == id {
            return location
        }
        
        return nil
    }
    
    public func getOneByDeviceLocally(_ deviceId: String) -> LocationModel? {
        for location in _locations {
            for device in location.devices where device.id == deviceId {
                return location
            }
        }
        
        return nil
    }
    
    public func addLocationLocally(_ location: LocationModel, asSelected: Bool = false) {
        _locations.append(location)
        if asSelected {
            UserSessionManager.shared.selectedLocationId = location.id
        }
    }
    
    // MARK: - Real time data methods
    public func startTrackingDevice(_ device: DeviceModel) {
        StatusManager.shared.trackDevices([device]) { (status) in
            if let device = self.updateDeviceStatus(status) {
                NotificationCenter.default.post(Notification(
                    name: device.statusUpdateNotificationName,
                    object: nil,
                    userInfo: status.dictionary
                ))
            }
        }
    }
    
    public func startTrackingDevices(_ locationId: String) {
        var devices: [DeviceModel] = []
        for location in _locations where location.id == locationId {
            devices = location.devices
            break
        }
        
        if !devices.isEmpty {
            StatusManager.shared.trackDevices(devices) { (status) in
                if let device = self.updateDeviceStatus(status) {
                    NotificationCenter.default.post(Notification(
                        name: device.statusUpdateNotificationName,
                        object: nil,
                        userInfo: status.dictionary
                    ))
                }
            }
        }
    }
    
    public func stopTrackingDevices() {
        StatusManager.shared.stopTracking()
    }
    
    // MARK: - API calls
    public func getOne(_ id: String, _ callback: @escaping (FloRequestErrorModel?, LocationModel?) -> Void) {
        FloApiRequest(
            controller: "v2/locations/\(id)",
            method: .get,
            queryString: ["expand": "devices"],
            data: nil,
            done: { (error, data) in
                if let e = error {
                    callback(e, nil)
                } else {
                    let location = LocationModel(data)
                    self.updateLocationLocally(id: id, location)
                    callback(nil, location)
                }
            }
        ).secureFloRequest()
    }
    
    public func getAll(_ callback: @escaping (Bool) -> Void) {
        var locationIds: [String] = []
        for location in _locations {
            locationIds.append(location.id)
        }
        
        getAllRecursive(locationIds: locationIds) { success in
            callback(success)
        }
    }
    
    fileprivate func getAllRecursive(locationIds: [String], _ callback: @escaping (Bool) -> Void) {
        var remainingIds = locationIds
        
        if let locationId = remainingIds.popLast() {
            getOne(locationId) { (error, _) in
                if error != nil {
                    callback(false)
                } else {
                    self.getAllRecursive(locationIds: remainingIds, callback)
                }
            }
        } else {
            callback(true)
        }
    }
}
