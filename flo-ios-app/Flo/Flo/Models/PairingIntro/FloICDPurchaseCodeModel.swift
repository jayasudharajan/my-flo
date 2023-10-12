//
//  FloICDPurchaseCodeModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/25/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class FloICDPurchaseCodeModel: Mappable {
    
    public var encryptCode: String?
    public var id: String?
    public var data: String?
    
    public var purchaseICDJson: [String: AnyObject]? {
        if encryptCode != .none && id != .none {
            return self.toJSON() as [String: AnyObject]?
        } else {
            return .none
        }
    }
    
    required init?(map: Map) {}
    
    public func mapping(map: Map) {
        encryptCode <- map["e"]
        id <- map["i"]
    }
}
