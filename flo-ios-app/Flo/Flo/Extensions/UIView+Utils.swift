//
//  UIView+Utils.swift
//  Flo
//
//  Created by Josefina Perez on 31/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    public func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let rectShape = CAShapeLayer()
        rectShape.bounds = frame
        rectShape.position = center
        
        rectShape.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners,
                                      cornerRadii: CGSize(width: radius, height: radius)).cgPath
        layer.mask = rectShape
    }
    
    public func removeRoundCorners() {
        layer.mask = nil
    }
}
