//
//  SignupEmailViewController.swift
//  Flo
//
//  Created by Matias Paillet on 5/24/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//
import UIKit

internal class SignupEmailViewController: FloBaseViewController, SignUpStep {
    
    @IBOutlet fileprivate weak var txtEmail: UITextField!
    @IBOutlet fileprivate weak var txtPassword: UITextField!
    @IBOutlet fileprivate weak var txtPasswordConfirmation: UITextField!
    
    public weak var delegate: SignupViewController?
    public var prefilledEmail: String?
    fileprivate var validator: Validator!
    
    // MARK: Lifecycle
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.validator = Validator(objectsToValidate: textFieldsToValidate())
        
        configureView()
    }
    
    fileprivate func configureView() {
        
        //UI Customization
        txtPassword.addSecureTextEntrySwitch()
        txtPasswordConfirmation.addSecureTextEntrySwitch()
        
        txtEmail.text = prefilledEmail
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let e = prefilledEmail, !e.isEmpty() {
            _ = performValidationsOn(txtEmail)
        }
    }
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtEmail, txtPassword, txtPasswordConfirmation]
    }
    
    // MARK: SignUpStep
    
    public func performIsValidCheck(_ andThen:@escaping (_ success: Bool) -> Void) {
        let textFields = textFieldsToValidate()
        for txt in textFields {
            if !self.performValidationsOn(txt) {
                return
            }
        }
        
        if !validator.allChecksPassed() {
            delegate?.disableNextStep()
            return
        }
        
        self.showLoadingSpinner("Loading")
        
        let params = ["email": txtEmail.text!]
        FloApiRequest(controller: "v2/users/register",
                      method: .get,
                      queryString: params,
                      data: nil,
                      done: { (error, data) in
            self.hideLoadingSpinner()
            
            if let responseData = data as? NSDictionary {
                guard let isRegistered = responseData["isRegistered"] as? Bool, isRegistered == false else {
                    self.txtEmail.displayError("email_already_exists".localized)
                    return
                }
                
                guard let isPending = responseData["isPending"] as? Bool, isPending == false else {
                    self.delegate?.openVerifyEmailAddress(self.txtEmail.text!)
                    return
                }
                
                //If everything is ok, populate the builder and call the callback.
                SignUpBuilder.shared.setEmail(self.txtEmail.text!, andPassword: self.txtPassword.text!)
                andThen(true)
            } else {
                if let e = error {
                    self.showPopup(error: e)
                }
            }
        }).unsecureFloRequest()
    }
    
    fileprivate func isValidConfirmationPassword() -> Bool {
        return self.txtPassword.text == self.txtPasswordConfirmation.text
    }
    
    // MARK: UITextFieldDelegate and Validations
    
    override public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField != txtPassword && textField != txtPasswordConfirmation {
            _ = super.textFieldShouldEndEditing(textField)
        }
        return true
    }
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _  = performValidationsOn(textField)
        return
    }
        
    func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtEmail:
            guard self.txtEmail.text?.isValidEmail() ?? false else {
                txtEmail.displayError("please_enter_a_valid_email".localized)
                validator.markAsInvalid(txtEmail)
                break
            }
            validator.markAsValid(txtEmail)
            
        case txtPassword:
            guard !(self.txtPassword.text?.isEmpty() ?? true) else {
                txtPassword.displayError("password_not_empty".localized)
                validator.markAsInvalid(txtPassword)
                break
            }
            
            guard self.txtPassword.text?.isValidPassword() ?? false else {
                txtPassword.displayError("password_validation".localized)
                validator.markAsInvalid(txtPassword)
                break
            }
            validator.markAsValid(txtPassword)
            
        case txtPasswordConfirmation:
            guard self.isValidConfirmationPassword() else {
                txtPasswordConfirmation.displayError("passwords_do_not_match".localized)
                validator.markAsInvalid(txtPasswordConfirmation)
                break
            }
            validator.markAsValid(txtPasswordConfirmation)
            
        default:
            break
        }
        
        checkValidationsAndUpdateUI()
        
        return true
    }
    
    public func checkValidationsAndUpdateUI() {
        if validator.allChecksPassed() {
            delegate?.enableNextStep()
        } else {
            delegate?.disableNextStep()
        }
    }
    
}
