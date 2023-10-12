//
//  AccountModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 05/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal class AccountModel: JsonParsingProtocol {
    
    let id: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let id = json["id"].string
        else {
            LoggerHelper.log("Error parsing AccountModel", level: .error)
            return nil
        }
        
        self.id = id
    }
    
}
