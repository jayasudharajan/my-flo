//
//  AlertPopupWiFiCredsHeader.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertPopupWiFiCredsHeader: UIView, AlertPopupHeaderProtocol, UITextFieldDelegate {
    
    @IBOutlet fileprivate weak var ssidTextField: UITextField!
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        passwordTextField.addSecureTextEntrySwitch(startingSecured: false)
    }
    
    // MARK: - Instantiation
    public class func getInstance() -> AlertPopupWiFiCredsHeader {
        if let view = UINib(nibName: String(describing: AlertPopupWiFiCredsHeader.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as? AlertPopupWiFiCredsHeader {
            return view
        }
        
        return AlertPopupWiFiCredsHeader()
    }
    
    // MARK: - View getter
    public func getSsid() -> String {
        return ssidTextField.text ?? ""
    }
    
    public func getPassword() -> String {
        return passwordTextField.text ?? ""
    }
    
    // MARK: - AlertPopupHeader protocol methods
    public func allowsDismiss() -> Bool {
        return (validateSsid() && validatePassword())
    }
    
    // MARK: - Textfields protocol methods
    
    //Trim whitespaces on every textfield on the flow
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField != passwordTextField {
            textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.cleanError()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == ssidTextField {
            _ = validateSsid()
        } else {
            _ = validatePassword()
        }
    }
    
    // MARK: - Text fields validation
    fileprivate func validateSsid() -> Bool {
        ssidTextField.resignFirstResponder()
        let ssid = ssidTextField.text ?? ""
        
        if ssid.isEmpty {
            ssidTextField.displayError("wifi_ssid_validation".localized)
            return false
        }
        
        return true
    }
    
    fileprivate func validatePassword() -> Bool {
        passwordTextField.resignFirstResponder()
        let password = passwordTextField.text ?? ""
        
        if password.isShorterThan(8) || password.isLongerThan(63) {
            passwordTextField.displayError("wifi_password_validation".localized)
            return false
        }
        
        return true
    }
    
}
