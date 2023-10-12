//
//  FloArray.swift
//  Flo
//
//  Created by Nicolás Stefoni on 15/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

extension Array {
    
    func convertToObject<M: Mappable>() -> [M]? {
        if let obj = Mapper<M>().mapArray(JSONObject: self) {
            return obj
        }
        
        return nil
    }
    
}
