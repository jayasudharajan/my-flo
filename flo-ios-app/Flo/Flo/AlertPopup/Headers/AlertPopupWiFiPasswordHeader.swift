//
//  AlertPopupWiFiPasswordHeader.swift
//  Flo
//
//  Created by Nicolás Stefoni on 20/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertPopupWiFiPasswordHeader: UIView, AlertPopupHeaderProtocol, UITextFieldDelegate {
    
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        passwordTextField.addSecureTextEntrySwitch(startingSecured: false)
    }
    
    // MARK: - Instantiation
    public class func getInstance() -> AlertPopupWiFiPasswordHeader {
        if let view = UINib(nibName: String(describing: AlertPopupWiFiPasswordHeader.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as? AlertPopupWiFiPasswordHeader {
            return view
        }
        
        return AlertPopupWiFiPasswordHeader()
    }
    
    // MARK: - View getter
    public func getPassword() -> String {
        return passwordTextField.text ?? ""
    }
    
    // MARK: - AlertPopupHeader protocol methods
    public func allowsDismiss() -> Bool {
        return validatePassword()
    }
    
    // MARK: - Textfields protocol methods
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        passwordTextField.cleanError()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        _ = validatePassword()
    }
    
    // MARK: - Text fields validation
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
