//
//  NSError+Utils.swift
//  Flo
//
//  Created by Matias Paillet on 6/3/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

extension NSError {
    
    class func initWithMessage(_ message: String) -> NSError {
        let details = [NSLocalizedDescriptionKey: message]
        return NSError(domain: "FLO", code: 001, userInfo: details)
    }
}
