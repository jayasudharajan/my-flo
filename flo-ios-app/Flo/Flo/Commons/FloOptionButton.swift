//
//  FloOptionButton.swift
//  Flo
//
//  Created by Matias Paillet on 6/7/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

@IBDesignable
internal class FloOptionButton: UIButton {
    
    //Key used by the backend / api to map this option
    @IBInspectable var backendIdentifier: String?
    
    fileprivate var gradientLayer: CALayer?
    
    override var isSelected: Bool {
        willSet {
            if newValue == self.isSelected {
                return
            }
            
            if newValue && self.gradientLayer != nil {
                configureForSelected()
            } else {
                configureForUnselected()
            }
        }
    }
    
    public func configureForSelected() {
        self.layer.insertSublayer(self.gradientLayer!, at: 0)
        self.layer.shadowOpacity = 0.6
    }
    
    public func configureForUnselected() {
        self.gradientLayer?.removeFromSuperlayer()
        self.layer.shadowOpacity = 0
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.white
        self.tintColor = UIColor.clear
        self.setTitleColor(StyleHelper.colors.white, for: .selected)
        self.setTitleColor(StyleHelper.colors.disabledDarkBlue, for: .normal)
        self.titleLabel?.font = StyleHelper.font(sized: .small)
        self.titleLabel?.lineBreakMode = .byTruncatingTail
        self.layer.cornerRadius = 10
        
        self.layer.shadowColor = StyleHelper.colors.gradient1Secondary.cgColor
        self.layer.shadowRadius = 8
        self.layer.shadowOpacity = 0
        
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
        self.layer.masksToBounds = false
        
        self.gradientLayer = self.layer.createGradient(
            from: StyleHelper.colors.gradient1Main,
            to: StyleHelper.colors.gradient1Secondary,
            angle: 43)
        self.gradientLayer?.cornerRadius = 10
        self.gradientLayer?.masksToBounds = true
    }
    
}
