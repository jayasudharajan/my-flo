//
//  UserSessionManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 3/22/19.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Locksmith

internal class UserSessionManager: NSObject {
    
    public class var shared: UserSessionManager {
        struct Static {
            static let instance = UserSessionManager()
        }
        return Static.instance
    }
    
    fileprivate var cachedAuthorization: OAuthModel?
    var authorization: OAuthModel? {
        if cachedAuthorization == nil {
            cachedAuthorization = loadAuthorization()
        }
        
        return cachedAuthorization
    }
    
    public var user: UserModel?
    public var pushToken: String?
    
    fileprivate let kSelectedLocationIdKey = "selectedLocationId"
    fileprivate var _selectedLocationId: String?
    public var selectedLocationId: String? {
        get {
            var locationId = _selectedLocationId
            if locationId == nil {
                locationId = UserDefaults.standard.string(forKey: kSelectedLocationIdKey)
                if locationId == nil {
                    locationId = LocationsManager.shared.firstLocationId
                    if let id = locationId {
                        UserDefaults.standard.set(id, forKey: kSelectedLocationIdKey)
                    }
                }
                
                _selectedLocationId = locationId
            }
            
            return locationId
        }
        set {
            _selectedLocationId = newValue
            UserDefaults.standard.set(newValue, forKey: kSelectedLocationIdKey)
        }
    }
    
    // Constants for Locksmith
    fileprivate let kAuhtorizationAccount = "flo_auth_account"
    fileprivate let kAuthorizationKey = "flo_auth_key"
    fileprivate let kJwtAccount = "flo_jwt_account"
    fileprivate let kJwtKey = "flo_jwt_key"
    
    public func upsertAuthorization(_ auth: OAuthModel) {
        if auth.userId == "" { // Just for tracking
            TrackingManager.shared.track("upsert_user_id_empty")
        }
        
        if auth.jwt.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty { // Just for tracking
            TrackingManager.shared.track("upsert_user_empty_token")
        }
            
        cachedAuthorization = auth
            
        do {
            try Locksmith.updateData(data: [kAuthorizationKey: auth], forUserAccount: kAuhtorizationAccount)
            try Locksmith.updateData(data: [kJwtKey: auth.jwt as Any], forUserAccount: kJwtAccount)
            TrackingManager.shared.track("upsert_user_succedded")
        } catch let exception as LocksmithError {
            LoggerHelper.log(exception)
            TrackingManager.shared.track("upsert_user_failed", detail: exception.rawValue)
        } catch let exception as NSError {
            LoggerHelper.log(exception)
            TrackingManager.shared.track("upsert_user_failed", detail: exception.localizedDescription)
        }
    }
    
    fileprivate func loadAuthorization() -> OAuthModel? {
        if let auth = Locksmith.loadDataForUserAccount(userAccount: kAuhtorizationAccount)?[kAuthorizationKey] as? OAuthModel {
            if auth.jwt.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                if let token = Locksmith.loadDataForUserAccount(userAccount: kJwtAccount)?[kJwtKey] as? String {
                    TrackingManager.shared.track("get_user_succedded_2nd_store")
                    auth.jwt = token
                    return auth
                } else {
                    TrackingManager.shared.track("get_user_failed_2nd_store")
                    return nil
                }
            } else {
                return auth
            }
        } else {
            TrackingManager.shared.track("get_user_failed")
            return nil
        }
    }
    
    public func logout() {
        // Clears tacking data
        TrackingManager.shared.reset()
        LocationsManager.shared.reset()
        StatusManager.shared.logout()
        FloApiRequest.shouldMockServices(shouldMock: false)
        
        cachedAuthorization = nil
        user = nil
        _selectedLocationId = nil
        UserDefaults.standard.removeObject(forKey: "selectedLocationId")
        
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: kAuhtorizationAccount)
            TrackingManager.shared.track("delete_user_succedded")
        } catch let exception as LocksmithError {
            LoggerHelper.log(exception)
            TrackingManager.shared.track("delete_user_failed", detail: exception.rawValue)
        } catch let exception as NSError {
            LoggerHelper.log(exception)
            TrackingManager.shared.track("delete_user_failed", detail: exception.localizedDescription)
        }
    }
    
    public func getUser(_ callback: @escaping (FloRequestErrorModel?, UserModel?) -> Void) {
        if let userId = authorization?.userId {
            FloApiRequest(
                controller: "v2/users/\(userId)",
                method: .get,
                queryString: ["expand": "locations"],
                data: nil,
                done: { (error, data) in
                    if let e = error {
                        callback(e, nil)
                    } else {
                        self.user = UserModel(data)
                        callback(nil, self.user)
                    }
                }
            ).secureFloRequest()
        } else {
            callback(nil, nil)
        }
    }
    
    // MARK: - Old methods
    func checkUserSubscription(_ userId: String, _ result: @escaping (Bool, String) -> Void) {
        FloApiRequest(controller: "v1/subscriptions/user/\(userId)", method: .get, queryString: nil, data: nil, done: { (_, data) in
            if let r = data as? [String: AnyObject], let status = r["status"] as? String {
                if status == "active" || status == "trialing" {
                    result(true, status + "_subscriber")
                } else {
                    result(false, status + "_subscriber")
                }
            } else {
                result(false, "not_subscribed")
            }
        }).secureFloRequest()
    }
}
