//
//  CircularProgressView.swift
//  Flo
//
//  Created by Josefina Perez on 30/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class CircularProgressView: UIView {
    
    var endPercent: Int = 0
    var lineHeight: CGFloat = 0.0

    public func drawProgress(endPercent: Int, lineHeight: CGFloat) {
        self.endPercent = endPercent
        self.lineHeight = lineHeight
        self.setNeedsDisplay()
    }
    
    fileprivate func addProgressLine(angle: CGFloat, progressLineHeight: CGFloat) {
        let c = CGPoint(x: self.center.x - 9, y: self.center.y - 9)
        let r: CGFloat = progressLineHeight
        let finalPointX =  c.x + r * cos(angle)
        let finalPointY = c.y + r * sin(angle)
        
        let aPath = UIBezierPath()
        aPath.move(to: c)
        aPath.addLine(to: CGPoint(x: finalPointX, y: finalPointY))
        aPath.close()
    
        StyleHelper.colors.progressCircleColor.set()
        aPath.stroke()
        aPath.fill()
        
        let layer = CAShapeLayer()
        layer.path = aPath.cgPath
        layer.strokeColor = StyleHelper.colors.progressCircleColor.cgColor
        layer.lineWidth = 1
        layer.fillColor = StyleHelper.colors.progressCircleColor.cgColor
        layer.name = "line"
        layer.masksToBounds = false
        
        guard let sublayer = self.layer.sublayers?.first(where: { $0.name == "line" }) else {
            self.layer.addSublayer(layer)
            return
        }
        
        self.layer.replaceSublayer(sublayer, with: layer)
    }
    
    fileprivate func toRadians(angle: Int) -> CGFloat {
        return CGFloat(Double(angle) * (Double.pi / 180))
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let center = CGPoint(x: self.center.x - 9, y: self.center.y - 9)
        let radius = frame.width / 2
        
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: toRadians(angle: -90),
                    endAngle: toRadians(angle: (endPercent * 360 / 100) - 90), clockwise: true)
        
        path.close()
        StyleHelper.colors.progressCircleColor.setFill()
        path.fill()
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillColor = StyleHelper.colors.progressCircleColor.cgColor
        layer.name = "progress"
        
        addProgressLine(angle: toRadians(angle: (endPercent * 360 / 100) - 90), progressLineHeight: lineHeight)
        
        guard let sublayer = layer.sublayers?.first(where: { $0.name == "progress" }) else {
            self.layer.addSublayer(layer)
            return
        }
        
        self.layer.replaceSublayer(sublayer, with: layer)
    }

}
