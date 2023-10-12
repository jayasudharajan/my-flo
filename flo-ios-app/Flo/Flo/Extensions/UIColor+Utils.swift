//
//  FloUIColor.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/25/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString = String(cString.split(separator: "#").last ?? "")
        }
        
        var colorValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&colorValue)
        
        switch cString.count {
        case 6:
            self.init(
                red: CGFloat((colorValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((colorValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(colorValue & 0x0000FF) / 255.0,
                alpha: 1
            )
        case 8:
            self.init(
                red: CGFloat((colorValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((colorValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((colorValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(colorValue & 0x000000FF) / 255.0
            )
        default:
            self.init(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
}
