//
//  UIButton+Utils.swift
//  Flo
//
//  Created by Nicolás Stefoni on 21/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

extension UIButton {
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            clipsToBounds = newValue > 0
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    public func setAsEnabled() {
        isEnabled = true
        alpha = 1
    }
    
    public func setAsDisabled() {
        isEnabled = false
        alpha = 0.5
    }
    
    public func styleWhiteWithTransparency() {
        backgroundColor = StyleHelper.colors.whiteWithTransparency01
        layer.borderWidth = 1
        layer.borderColor = StyleHelper.colors.whiteWithTransparency015.cgColor
    }
    
    // MARK: - Location
    public func styleSquareWithRoundCorners(borderColor: CGColor? = nil) {
        backgroundColor = UIColor.white
        tintColor = UIColor.clear
        setTitleColor(StyleHelper.colors.darkBlue, for: .normal)
        titleLabel?.font = StyleHelper.font(sized: .small)
        titleLabel?.lineBreakMode = .byTruncatingTail
        cornerRadius = 10
        layer.borderColor = borderColor
        layer.borderWidth = borderColor != nil ? 1 : 0
    }
    
}
