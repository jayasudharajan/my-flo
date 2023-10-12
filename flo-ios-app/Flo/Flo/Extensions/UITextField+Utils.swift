//
//  FloUITextField.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/25/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

@IBDesignable extension UITextField {
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            borderStyle = .none
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.masksToBounds = true
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var leftPadding: CGFloat {
        get {
            return leftView?.frame.width ?? 01
        }
        set {
            if newValue > 0 {
                leftView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: newValue))
                leftViewMode = .always
            }
        }
    }
    
    @IBInspectable var placeholderColor: UIColor? {
        get {
            return self.placeholderColor
        }
        set {
            attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: newValue ?? .gray])
        }
    }
    
}

extension UITextField {
    
    public func setupWith(image: String?, colored: Bool = true) {
        if colored {
            backgroundColor = StyleHelper.colors.blue
        }
        if let src = image {
            let imageview = UIImageView(frame: CGRect(x: 12, y: 0, width: 18, height: 18))
            imageview.image = (UIImage(named: src) ?? UIImage()).resize(scaleX: 1, scaleY: 1)
            imageview.contentMode = .scaleAspectFit
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
            view.addSubview(imageview)
            leftView?.frame = imageview.frame
            leftView = view
            leftViewMode = .always
        }
    }
    
    // MARK: - Secure text entry
    public func addSecureTextEntrySwitch(startingSecured: Bool = true) {
        let secureTextEntryBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        secureTextEntryBtn.addTarget(self, action: #selector(switchTextVisibility), for: .touchUpInside)
        
        if startingSecured {
            secureTextEntryBtn.setImage(UIImage(named: "visible-input-icon"), for: .normal)
        } else {
            secureTextEntryBtn.setImage(UIImage(named: "hidden-input-icon"), for: .normal)
        }
        
        let btnContainer = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: secureTextEntryBtn.frame.width + 20, height: secureTextEntryBtn.frame.height)
        ))
        btnContainer.addSubview(secureTextEntryBtn)
        rightView = btnContainer
        rightViewMode = .always
    }
    
    @objc fileprivate func switchTextVisibility(_ sender: UIButton) {
        isSecureTextEntry = !isSecureTextEntry
        
        if isSecureTextEntry {
            sender.setImage(UIImage(named: "visible-input-icon"), for: .normal)
        } else {
            sender.setImage(UIImage(named: "hidden-input-icon"), for: .normal)
        }
    }
    
    public func addRightImage(named: String, withTarget target: AnyObject, andAction action: Selector) {
        let secureTextEntryBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        secureTextEntryBtn.setImage(UIImage(named: named), for: .normal)
        secureTextEntryBtn.addTarget(target, action: action, for: .touchUpInside)
        
        let btnContainer = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: secureTextEntryBtn.frame.width + 20, height: secureTextEntryBtn.frame.height)
        ))
        btnContainer.addSubview(secureTextEntryBtn)
        rightView = btnContainer
        rightViewMode = .always
    }
    
    public func addLeftView(_ view: UIView, withTarget target: AnyObject, andAction action: Selector) {
        let secureTextEntryBtn = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        secureTextEntryBtn.addTarget(target, action: action, for: .touchUpInside)
        
        let btnContainer = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: secureTextEntryBtn.frame.width, height: secureTextEntryBtn.frame.height)
        ))
        btnContainer.addSubview(view)
        btnContainer.addSubview(secureTextEntryBtn)
        leftView = btnContainer
        leftViewMode = .always
    }
    
    public func addRightText(_ text: String) {
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        lbl.font = StyleHelper.font(sized: .small)
        lbl.textColor = StyleHelper.colors.darkBlue
        lbl.backgroundColor = UIColor.clear
        lbl.text = text
        lbl.sizeToFit()
        
        let btnContainer = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: lbl.frame.width, height: lbl.frame.height)
        ))
        
        btnContainer.addSubview(lbl)
        rightView = btnContainer
        rightViewMode = .always
    }
    
    // MARK: - Validation
    public func displayError(_ message: String) {
        FloTooltip.remove(from: self)
        layer.borderColor = StyleHelper.colors.red.cgColor
        
        let tooltip = FloTooltip(create: .error, pointing: .bottom, saying: message)
        tooltip.show(over: self)
    }
    
    func cleanError(cleaningAllOtherBubbles: Bool = true) {
        FloTooltip.remove(from: self, cleaningAllOtherBubbles: cleaningAllOtherBubbles)
        layer.borderColor = StyleHelper.colors.darkBlue.withAlphaComponent(0.2).cgColor
    }
    
}
