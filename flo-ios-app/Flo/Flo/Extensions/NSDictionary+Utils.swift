//
//  FloNSDictionary.swift
//  Flo
//
//  Created by Nicolás Stefoni on 15/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

extension NSDictionary {
    
    func convertToObject<M: Mappable>() -> M? {
        if let json = self as? [String: Any], let obj = Mapper<M>().map(JSON: json) {
            return obj
        }
        
        return nil
    }
    
}
