//
//  PlistHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 11/04/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class PlistHelper {
    
    public class func valueForKey(_ key: String) -> Any? {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            return dict[key]
        }
        return nil
    }
    
    public class func dataForKey(_ key: String?, type: String?) -> Data? {
        if let path = Bundle.main.path(forResource: key, ofType: type) {
            do {
                let data: Data = try Data(contentsOf: URL(fileURLWithPath: path))
                return data
            } catch let exception {
                LoggerHelper.log(exception)
                return nil
            }
        }
        return nil
    }
    
}
