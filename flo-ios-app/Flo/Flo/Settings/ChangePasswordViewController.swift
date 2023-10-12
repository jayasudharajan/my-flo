//
//  ChangePasswordViewController.swift
//  Flo
//
//  Created by Josefina Perez on 05/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class ChangePasswordViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var txtOldPassword: UITextField!
    @IBOutlet fileprivate weak var txtNewPassword: UITextField!
    @IBOutlet fileprivate weak var txtConfirmPassword: UITextField!
    @IBOutlet fileprivate weak var btnChangePassword: UIButton!
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtOldPassword, txtNewPassword, txtConfirmPassword]
    }
    
    fileprivate var validator: Validator!

    override func viewDidLoad() {
        super.viewDidLoad()
        
      view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
       setupNavBarWithBack(andTitle: "change_password".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        
        self.validator = Validator(objectsToValidate: textFieldsToValidate())
        
        txtOldPassword.addSecureTextEntrySwitch()
        txtNewPassword.addSecureTextEntrySwitch()
        txtConfirmPassword.addSecureTextEntrySwitch()
        
        btnChangePassword.setAsDisabled()
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: UITextFieldDelegate and Validations
    
    override public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        //Override Base class behavior, so doesn't trim passwords
        return true
    }
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _  = performValidationsOn(textField)
        return
    }
    
    override public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtOldPassword:
            guard !(self.txtOldPassword.text?.isEmpty() ?? true) else {
                txtOldPassword.displayError("password_not_empty".localized)
                validator.markAsInvalid(txtOldPassword)
                break
            }
            
            guard self.txtOldPassword.text?.isValidPassword() ?? false else {
                txtOldPassword.displayError("password_validation".localized)
                validator.markAsInvalid(txtOldPassword)
                break
            }
            validator.markAsValid(txtOldPassword)
            
        case txtNewPassword:
            guard !(self.txtNewPassword.text?.isEmpty() ?? true) else {
                txtNewPassword.displayError("password_not_empty".localized)
                validator.markAsInvalid(txtNewPassword)
                break
            }
            
            guard self.txtNewPassword.text?.isValidPassword() ?? false else {
                txtNewPassword.displayError("password_validation".localized)
                validator.markAsInvalid(txtNewPassword)
                break
            }
            validator.markAsValid(txtNewPassword)
            
        case txtConfirmPassword:
            guard self.isValidConfirmationPassword() else {
                txtConfirmPassword.displayError("passwords_do_not_match".localized)
                validator.markAsInvalid(txtConfirmPassword)
                break
            }
            validator.markAsValid(txtConfirmPassword)
            
        default:
            break
        }
        
        checkValidationsAndUpdateUI()
        
        return true
    }
    
    fileprivate func isValidConfirmationPassword() -> Bool {
        return self.txtNewPassword.text == self.txtConfirmPassword.text
    }
    
    public func checkValidationsAndUpdateUI() {
        if validator.allChecksPassed() {
            btnChangePassword.setAsEnabled()
        } else {
            btnChangePassword.setAsDisabled()
        }
    }
    
    // MARK: - Actions
    
    @IBAction fileprivate func changePassword() {
        
        guard !FloApiRequest.demoModeEnabled() else {
            showFeatureNotSupportedInDemoModeAlert()
            return
        }
        
        let textFields = textFieldsToValidate()
        for txt in textFields {
            if !self.performValidationsOn(txt) {
                return
            }
        }
        
        if !validator.allChecksPassed() {
            btnChangePassword.setAsDisabled()
            return
        }
        
        guard let user = UserSessionManager.shared.user, let oldPassword = txtOldPassword.text,
        let newPassword = txtNewPassword.text else {
            return
        }
        
        self.showLoadingSpinner("loading".localized)
        
        FloApiRequest(
            controller: "v2/users/\(user.id)/password",
            method: .post,
            queryString: nil,
            data: ["oldPassword": oldPassword as AnyObject,
                   "newPassword": newPassword as AnyObject],
            done: { (error, _ ) in
                self.hideLoadingSpinner()
                if let e = error {
                    if let serverMessage = e.originalServerMessage, serverMessage == "Your current password is incorrect." {
                        self.showPopup(title: "error_popup_title".localized() + " 010",
                                       description: "incorrect_current_password_please_try_again".localized())
                    } else {
                        self.showPopup(error: e)
                    }
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
        }).secureFloRequest()
    }
}
