//
//  AlertPopupEmailHeader.swift
//  Flo
//
//  Created by Nicolás Stefoni on 29/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol AlertPopupHeaderProtocol: class {
    func allowsDismiss() -> Bool
}

internal class AlertPopupEmailHeader: UIView, AlertPopupHeaderProtocol, UITextFieldDelegate {
    
    @IBOutlet fileprivate weak var emailTextField: UITextField!
    
    // MARK: - Instantiation
    public class func getInstance() -> AlertPopupEmailHeader {
        if let view = UINib(nibName: String(describing: AlertPopupEmailHeader.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as? AlertPopupEmailHeader {
            return view
        }
        
        return AlertPopupEmailHeader()
    }
    
    // MARK: - View getter
    public func getEmail() -> String {
        return emailTextField.text ?? ""
    }
    
    // MARK: - AlertPopupHeader protocol methods
    public func allowsDismiss() -> Bool {
        return validateEmail()
    }
    
    // MARK: - Textfields protocol methods
    
    //Trim whitespaces on every textfield on the flow
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        emailTextField.cleanError()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        _ = validateEmail()
    }
    
    // MARK: - Text fields validation
    fileprivate func validateEmail() -> Bool {
        emailTextField.resignFirstResponder()
        let email = emailTextField.text ?? ""
        
        if email.isEmpty {
            emailTextField.displayError("email_not_empty".localized)
            return false
        } else if !email.isValidEmail() {
            emailTextField.displayError("please_enter_a_valid_email".localized)
            return false
        }
        
        return true
    }

}
