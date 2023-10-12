//
//  AlertPopupTextFieldHeader.swift
//  Flo
//
//  Created by Nicolás Stefoni on 11/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertPopupTextFieldHeader: UIView, AlertPopupHeaderProtocol, UITextFieldDelegate {
    
    @IBOutlet fileprivate weak var textField: UITextField!
    
    // MARK: - Instantiation
    public class func getInstance() -> AlertPopupTextFieldHeader {
        if let view = UINib(nibName: String(describing: AlertPopupTextFieldHeader.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as? AlertPopupTextFieldHeader {
            return view
        }
        
        return AlertPopupTextFieldHeader()
    }
    
    // MARK: - View getter
    public func getText() -> String {
        return textField.text ?? ""
    }
    
    // MARK: - AlertPopupHeader protocol methods
    public func allowsDismiss() -> Bool {
        return validateText()
    }
    
    // MARK: - Textfields protocol methods
    
    //Trim whitespaces on every textfield on the flow
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.cleanError()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        _ = validateText()
    }
    
    // MARK: - Text fields validation
    fileprivate func validateText() -> Bool {
        textField.resignFirstResponder()
        let text = textField.text ?? ""
        
        if text.isEmpty {
            textField.displayError("should_not_be_empty".localized)
            return false
        }
        
        return true
    }
    
}
