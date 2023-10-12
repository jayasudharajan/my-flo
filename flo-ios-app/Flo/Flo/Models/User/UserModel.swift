//
//  UserModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 22/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal class UserModel: JsonParsingProtocol {
    
    fileprivate(set) var id: String
    fileprivate(set) var firstName: String
    fileprivate(set) var lastName: String
    fileprivate(set) var email: String
    fileprivate(set) var phoneMobile: String
    fileprivate(set) var unitSystem: MeasureSystem
    fileprivate(set) var locationRoles: [LocationRoleModel]
    fileprivate(set) var accountRole: AccountRoleModel
    fileprivate(set) var account: AccountModel
    public var developerMenu: Bool!
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let id = json["id"].string,
            let accountRole = AccountRoleModel(json["accountRole"].object as AnyObject),
            let account = AccountModel(json["account"].object as AnyObject)
        else {
            LoggerHelper.log("Error parsing UserModel", level: .error)
            return nil
        }
        
        self.id = id
        locationRoles = LocationRoleModel.array(json["locationRoles"].arrayObject)
        self.accountRole = accountRole
        self.account = account
        
        self.firstName = json["firstName"].string ?? ""
        self.lastName = json["lastName"].string ?? ""
        self.email = json["email"].string ?? ""
        
        self.phoneMobile = json["phoneMobile"].string ?? ""
        let unitSystemKey = json["unitSystem"].string
        self.unitSystem = unitSystemKey != nil ? (MeasureSystem(rawValue: unitSystemKey!) ?? .imperial) : .imperial
        
        var developerMenuEnabled = false
        if let featuresArray = json["enabledFeatures"].arrayObject as? [String], featuresArray.contains("developerMenu") {
            developerMenuEnabled = true
        }
        self.developerMenu = developerMenuEnabled
        
        //Set measure system for the entire application based on user's one
        MeasuresHelper.setMeasureSystem(self.unitSystem)
        
        LocationsManager.shared.locations = LocationModel.array(json["locations"].arrayObject)
    }
    
    public func setFirstName(_ firstName: String) {
        self.firstName = firstName
    }
    
    public func setLastName(_ lastName: String) {
        self.lastName = lastName
    }
    
    public func setPhone(_ phone: String) {
        self.phoneMobile = phone
    }
}
