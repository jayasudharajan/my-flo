//
//  RoleModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 04/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum RoleType: String {
    case owner
}

internal class LocationRoleModel: JsonParsingProtocol {
    
    let roles: [RoleType]
    let locationId: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let roleKeys = json["roles"].arrayObject as? [String],
            let locationId = json["locationId"].string
        else {
            LoggerHelper.log("Error parsing LocationRoleModel", level: .error)
            return nil
        }
        
        var receivedRoles: [RoleType] = []
        for roleKey in roleKeys {
            if let role = RoleType(rawValue: roleKey) {
                receivedRoles.append(role)
            }
        }
        
        self.roles = receivedRoles
        self.locationId = locationId
    }
    
    public class func array(_ objects: [Any]?) -> [LocationRoleModel] {
        var locationRoles: [LocationRoleModel] = []
        
        for object in objects ?? [] {
            if let locationRole = LocationRoleModel(object as AnyObject) {
                locationRoles.append(locationRole)
            }
        }
        
        return locationRoles
    }
    
}

internal class AccountRoleModel: JsonParsingProtocol {
    
    let roles: [RoleType]
    let accountId: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let roleKeys = json["roles"].arrayObject as? [String],
            let accountId = json["accountId"].string
            else {
                LoggerHelper.log("Error parsing AccountRoleModel", level: .error)
                return nil
        }
        
        var receivedRoles: [RoleType] = []
        for roleKey in roleKeys {
            if let role = RoleType(rawValue: roleKey) {
                receivedRoles.append(role)
            }
        }
        
        self.roles = receivedRoles
        self.accountId = accountId
    }
    
}
