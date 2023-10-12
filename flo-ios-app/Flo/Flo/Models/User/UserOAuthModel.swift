//
//  UserOAuthModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/31/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal enum OAuthGrantType: String {
    case password = "password", refreshToken = "refresh_token"
}

internal class UserOAuthModel: Mappable {
    
    var clientId: String!
    var clientSecret: String!
    var username: String?
    var password: String?
    var grantType: String!
    
    public init(username: String? = nil, password: String? = nil, grantType: OAuthGrantType) {
        clientId = (PlistHelper.valueForKey("FloApiClientID") as? String) ?? ""
        clientSecret = clientId
        self.username = username
        self.password = password
        self.grantType = grantType.rawValue
    }
    
    required public init?(map: Map) {}
    
    public func mapping(map: Map) {
        clientId <- map["client_id"]
        clientSecret <- map["client_secret"]
        username <- map["username"]
        password <- map["password"]
        grantType <- map["grant_type"]
    }
    
    public var userJson: [String: AnyObject]? {
        if username != nil && password != nil {
            return self.toJSON() as [String: AnyObject]?
        }
        
        return nil
    }
    
}
