//
//  RefreshUserTokenModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 4/12/17.
//  Copyright © 2017 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class RefreshUserTokenModel: Mappable {
    public var clientId: String!
    public var clientSecret: String!
    public var refreshToken: String!
    public var grantType = "refresh_token"
    
    init (clientId: String, refreshToken: String) {
        self.clientId = clientId
        clientSecret = clientId
        self.refreshToken = refreshToken
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        clientId <- map["client_id"]
        clientSecret <- map["client_secret"]
        refreshToken <- map["refresh_token"]
        grantType <- map["grant_type"]
    }
    
    func jsonify() -> [String: AnyObject]? {
        return self.toJSON() as [String: AnyObject]?
    }
}
