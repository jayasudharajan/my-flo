//
//  FloUIImage.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/17/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resizeImageWithAspect(_ size: CGSize) -> UIImage? {
        let oldWidth = self.size.width
        let oldHeight = self.size.height
        
        let scaleFactor = (oldWidth > oldHeight) ? size.width / oldWidth : size.height / oldHeight
        
        let newHeight = oldHeight * scaleFactor
        let newWidth = oldWidth * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        if UIScreen.main.responds(to: #selector(NSDecimalNumberBehaviors.scale)) {
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        } else {
            UIGraphicsBeginImageContext(newSize)
        }
        
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func resize(scaleX: CGFloat, scaleY: CGFloat) -> UIImage {
        let size = self.size.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage ?? UIImage()
    }
    
}
