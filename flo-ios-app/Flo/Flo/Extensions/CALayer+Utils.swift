//
//  CALayer+Utils.swift
//  Flo
//
//  Created by Nicolás Stefoni on 03/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    
    public func addDashedBorder(withColor color: UIColor) {
        let border = FloShapeLayer()
        border.strokeColor = color.cgColor
        border.lineDashPattern = [4, 4]
        border.frame = bounds
        border.fillColor = nil
        border.backgroundColor = nil
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        border.needsDisplayOnBoundsChange = true
        addSublayer(border)
    }
    
    public func addGradient(from color1: UIColor, to color2: UIColor, angle: Double) {
        self.insertSublayer(self.createGradient(from: color1, to: color2, angle: angle), at: 0)
    }
    
    public func createGradient(from color1: UIColor, to color2: UIColor, angle: Double) -> CALayer {
        let radians = -1 * angle * .pi / 180
        let gradient = FloGradientLayer()
        gradient.cornerRadius = cornerRadius
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.locations = [0, 1]
        
        var startPoint = CGPoint(x: 0, y: 0)
        var endPoint = CGPoint(x: cos(radians), y: sin(radians))
        
        if endPoint.x < 0 {
            startPoint.x = 1
            endPoint.x += 1
        }
        if endPoint.y < 0 {
            startPoint.y = 1
            endPoint.y += 1
        }
        
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.frame = bounds
        gradient.needsDisplayOnBoundsChange = true
        return gradient
    }
}

internal class FloShapeLayer: CAShapeLayer {
    
    override var needsDisplayOnBoundsChange: Bool {
        didSet {
            if needsDisplayOnBoundsChange == true {
                (superlayer ?? self).setNeedsDisplay()
            }
        }
    }
    
    override func display() {
        super.display()
        
        if let container = superlayer {
            frame = container.bounds
            path = UIBezierPath(roundedRect: container.bounds, cornerRadius: container.cornerRadius).cgPath
        }
    }
    
}

internal class FloGradientLayer: CAGradientLayer {
    
    override var needsDisplayOnBoundsChange: Bool {
        didSet {
            if needsDisplayOnBoundsChange == true {
                (superlayer ?? self).setNeedsDisplay()
            }
        }
    }
    
    override func display() {
        super.display()
        
        if let container = superlayer {
            frame = container.bounds
        }
    }
    
}
