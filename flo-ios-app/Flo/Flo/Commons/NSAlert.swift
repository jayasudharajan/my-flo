//
//  AlertView.swift
//  TestEnv
//
//  Created by Nicolás Stefoni on 28/9/17.
//  Copyright © 2017 Nicolás Stefoni. All rights reserved.
//

import UIKit

struct NSAlertStyle {
    
    public var backgroundColor = UIColor.black
    public var textColor = UIColor.white
    
    fileprivate init(backgroundColor: UIColor, textColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
}

struct NSAlertType {
    
    public static let error = NSAlertStyle(backgroundColor: UIColor.red, textColor: UIColor.white)
    public static let success = NSAlertStyle(backgroundColor: StyleHelper.colors.green, textColor: .white)
    public static let toast = NSAlertStyle(backgroundColor: UIColor.darkGray.withAlphaComponent(0.9), textColor: .white)
    
}

internal class NSAlert {
    
    // MARK: Singleton
    public class var shared: NSAlert {
        struct Static {
            static let instance = NSAlert()
        }
        return Static.instance
    }
    
    fileprivate let alertView = UIView()
    fileprivate let margin: CGFloat = 10
    fileprivate let bottomOffset: CGFloat = 50
    fileprivate let height: CGFloat = 50
    
    fileprivate var baseFrame = CGRect()
    fileprivate var textLbl = UILabel()
    fileprivate var timeOut: Double = 0
    fileprivate var timer: Timer?
    fileprivate var animDuration: Double = 0.55
    
    fileprivate var active = false
    
    fileprivate init() {
        // Configuring alert's view
        alertView.isUserInteractionEnabled = true
        alertView.clipsToBounds = true
        alertView.backgroundColor = .red
        
        // Configuring label
        textLbl.textColor = .white
        textLbl.numberOfLines = 10
        textLbl.textAlignment = .center
        alertView.addSubview(textLbl)
        textLbl.adjustsFontSizeToFitWidth = true
    }
    
    public func configure(font: UIFont? = nil, animDuration: Double? = nil) {
        // Configuring label
        if let newFont = font {
            textLbl.font = newFont
        }
        
        // Configuring timing
        if let newAnimDuration = animDuration {
            self.animDuration = newAnimDuration
        }
    }
    
    public func show(text: String, type: NSAlertStyle, timeOut: Double = 0, tapToDismiss: Bool = false) {
        active = true
        baseFrame = UIApplication.shared.keyWindow?.frame ?? CGRect()
        
        alertView.backgroundColor = type.backgroundColor
        textLbl.textColor = type.textColor
        
        // Configuring alert's view
        alertView.layer.removeAllAnimations()
        
        alertView.frame = CGRect(origin: CGPoint(x: margin * 2, y: baseFrame.height - 2 * height),
                                 size: CGSize(width: baseFrame.width - 4 * margin, height: height))
        alertView.alpha = 0
        alertView.layer.cornerRadius = height / 2
        
        alertView.removeFromSuperview()
        if tapToDismiss {
            alertView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        }
        
        // Configuring label
        textLbl.text = text
        textLbl.frame = CGRect(x: margin,
                               y: margin,
                               width: alertView.frame.width - margin * 2,
                               height: height - margin * 2)
        
        // Configuring timing
        timer?.invalidate()
        timer = nil
        self.timeOut = timeOut
        if timeOut > 0 {
            timer = Timer.scheduledTimer(timeInterval: timeOut + animDuration * 2,
                                         target: self,
                                         selector: #selector(dismiss),
                                         userInfo: nil,
                                         repeats: false)
        }
        
        UIApplication.shared.keyWindow?.addSubview(alertView)
        UIApplication.shared.keyWindow?.bringSubviewToFront(alertView)
        alertView.layer.zPosition = 100
        present()
    }
    
    fileprivate func present() {
        UIView.animate(
            withDuration: animDuration,
            animations: {
                self.alertView.alpha = 1
            }
        )
    }
    
    @objc public func dismiss() {
        if active {
            active = false
            timer?.invalidate()
            timer = nil
            
            UIView.animate(
                withDuration: animDuration,
                animations: {
                    self.alertView.alpha = 0
                }
            )
        }
    }
    
}
