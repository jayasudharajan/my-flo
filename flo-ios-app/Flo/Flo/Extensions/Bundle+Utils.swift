//
//  Bundle+Utils.swift
//  Flo
//
//  Created by Josefina Perez on 04/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

extension Bundle {
    
    var versionNumber: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") else {
            return ""
        }
        return String(describing: version)
    }
    
    var buildNumber: String {
        guard let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") else {
            return ""
        }
        return String(describing: buildNumber)
    }
}
