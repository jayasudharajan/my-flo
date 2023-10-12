//
//  DeveloperToolsHelper.swift
//  Flo
//
//  Created by Josefina Perez on 01/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeveloperToolsHelper: NSObject {
    
    fileprivate static var devicesWithDebugMessagesEnabled: [String] = []
    fileprivate static let kDeveloperToolsEnabledKey = "developerToolsEnabled"
    fileprivate(set) class var isEnabled: Bool {
        get {
            #if PROD
            return UserSessionManager.shared.user?.developerMenu ?? false
            #endif
            return UserDefaults.standard.bool(forKey: kDeveloperToolsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kDeveloperToolsEnabledKey)
        }
    }
    
    public class func enable() {
        isEnabled = true
    }
    
}
