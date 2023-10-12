//
//  OAuthModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 5/22/19.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Locksmith
import SwiftyJSON

internal final class OAuthModel: NSObject, NSCoding, JsonParsingProtocol {
    
    public var jwt: String
    fileprivate(set) var refreshJwt: String
    fileprivate(set) var tokenType: String
    fileprivate(set) var userId: String
    fileprivate var expiresDate: Date
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let jwt = json["access_token"].string,
            let refreshJwt = json["refresh_token"].string,
            let userId = json["user_id"].string,
            let expiresIn = json["expires_in"].double
        else {
            LoggerHelper.log("Error parsing OAuthModel", level: .error)
            return nil
        }
        
        self.jwt = jwt
        self.refreshJwt = refreshJwt
        self.tokenType = json["token_type"].string ?? "Bearer"
        self.userId = userId
        expiresDate = Date().addingTimeInterval(expiresIn)
    }
    
    fileprivate init(
        jwt: String,
        refreshJwt: String,
        expiresDate: Date,
        tokenType: String,
        userId: String
    ) {
        self.jwt = jwt
        self.refreshJwt = refreshJwt
        self.expiresDate = expiresDate
        self.tokenType = tokenType
        self.userId = userId
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        guard let jwt = decoder.decodeObject(forKey: "jwt") as? String,
            let refreshJwt = decoder.decodeObject(forKey: "refresh_jwt") as? String,
            let expiresDate = decoder.decodeObject(forKey: "expires_date") as? Date,
            let tokenType = decoder.decodeObject(forKey: "token_type") as? String,
            let userId = decoder.decodeObject(forKey: "user_id") as? String
        else {
            LoggerHelper.log("Error decoding OAuthModel", level: .error)
            return nil
        }
        
        self.init(
            jwt: jwt,
            refreshJwt: refreshJwt,
            expiresDate: expiresDate,
            tokenType: tokenType,
            userId: userId
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(jwt, forKey: "jwt")
        coder.encode(refreshJwt, forKey: "refresh_jwt")
        coder.encode(expiresDate, forKey: "expires_date")
        coder.encode(tokenType, forKey: "token_type")
        coder.encode(userId, forKey: "user_id")
    }
    
    public func tokenOutOfDate() -> Bool {
        if self.expiresDate.compare(Date()) == .orderedAscending {
            return true
        }
        
        return false
    }
    
}
