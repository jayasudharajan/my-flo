//
//  StyleHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 14/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import UIKit

enum FontSize: CGFloat {
    case tiny = 12, small = 16, medium = 18, large = 21, giant = 24
}

/*
 To see the real font names, place this 'for' loop into your code:
 for family in UIFont.familyNames.sorted() {
 let names = UIFont.fontNames(forFamilyName: family)
 print("Family: \(family) Font names: \(names)")
 }
 */

internal enum FontWeight: String {
    case regular = "Questrial-Regular"
}

@objc internal class Colors: NSObject {
    
    @objc public let white = UIColor(hex: "FFFFFF")
    @objc public let whiteWithTransparency02 = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 0.2)
    @objc public let whiteWithTransparency01 = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
    @objc public let whiteWithTransparency015 =  UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
    @objc public let black = UIColor(hex: "373737")
    @objc public let green = UIColor(hex: "70D549")
    @objc public let darkBlue = UIColor(hex: "073F62")
    @objc public let infoBlue = UIColor(hex: "12C3EA")
    @objc public let disabledDarkBlue = UIColor(hex: "839FB1")
    @objc public let gray = UIColor(hex: "CDD9E0")
    @objc public let darkGray = UIColor(hex: "888888")
    @objc public let cyan = UIColor(hex: "3EBBE2")
    @objc public let darkCyan = UIColor(hex: "2790BE")
    @objc public let darkOrange = UIColor(hex: "C65037")
    @objc public let orange = UIColor(hex: "EDA247")
    @objc public let salmon = UIColor(hex: "FF967C")
    
    @objc public let darkBlueDisabled = UIColor(hex: "849FAF")
    @objc public let blue = UIColor(hex: "0A537F")
    @objc public let lightBlue = UIColor(hex: "E0E9F2")
    @objc public let dripBlue = UIColor(hex: "C1E3F0")
    @objc public let lightGray = UIColor(hex: "EDF0F3")
    @objc public let red = UIColor(hex: "D75839")
    @objc public let darkRed = UIColor(hex: "78211B")
    @objc public let transparencyHighlight = UIColor(hex: "FFFFFF5E")
    @objc public let transparency = UIColor(hex: "FFFFFF16")
    @objc public let transparency20 = UIColor(hex: "FFFFFF33")
    @objc public let transparency50 = UIColor(hex: "FFFFFF80")
    @objc public let secondaryText = UIColor(hex: "7B97AA")
    @objc public let screenTitle = UIColor(hex: "000000")
    @objc public let mainButtonActive = UIColor(hex: "08537F")
    @objc public let mainButtonInactive = UIColor(hex: "A8C1D0")
    
    @objc public let buttonIcons = UIColor(hex: "90B5CB")
    @objc public let gradient1Main = UIColor(hex: "073F62")
    @objc public let gradient1Secondary = UIColor(hex: "0C679C")
    @objc public let gradientSecondaryGreen = UIColor(hex: "9AE17F")
    @objc public let progressCircleColor = UIColor(hex: "26A2EE")
}

@objc internal class StyleHelper: NSObject {
    
    @objc public static let colors = Colors()
    
    public class func font(sized size: FontSize, _ weight: FontWeight = .regular) -> UIFont {
        return UIFont(name: weight.rawValue, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
}
