//
//  UserSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 27/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class UserSettingsViewController: FloBaseViewController, PhonePrefixPickerDelegate {
    
    @IBOutlet fileprivate weak var txtFirstName: UITextField!
    @IBOutlet fileprivate weak var txtLastName: UITextField!
    @IBOutlet fileprivate weak var txtPhone: UITextField!
    @IBOutlet fileprivate weak var txtEmail: UITextField!
    
    public var shouldShowBackButton: Bool = true
    fileprivate var countryPhonePrefixPicker: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        countryPhonePrefixPicker = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: txtPhone.frame.height))
        countryPhonePrefixPicker.font = StyleHelper.font(sized: .medium)
        countryPhonePrefixPicker.backgroundColor = UIColor.clear
        countryPhonePrefixPicker.textColor = StyleHelper.colors.darkBlue
        countryPhonePrefixPicker.textAlignment = .center
        
        txtEmail.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowBackButton ? setupNavBarWithBack(andTitle: "edit_profile".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white) : setupNavBar(with: "edit_profile".localized)
        fillWithUserInformation()
    }
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtFirstName, txtLastName, txtPhone]
    }
    
    fileprivate func fillWithUserInformation() {
        guard let user = UserSessionManager.shared.user else {
            return
        }
        
        txtFirstName.text = user.firstName
        txtLastName.text = user.lastName
        txtPhone.text = user.phoneMobile.removeCountryCode()
        txtEmail.text = user.email
        
        countryPhonePrefixPicker.text = countryPhonePrefixPicker.text ?? "+ \(user.phoneMobile.getCountryCode() ?? "")"
        txtPhone.addLeftView(
            countryPhonePrefixPicker,
            withTarget: self,
            andAction: #selector(openCountryCodePicker))
    }
    
    fileprivate func updateFirstName(_ firstName: String) {
        updateUserInformation(data: ["firstName": firstName as AnyObject], callback: {
            UserSessionManager.shared.user?.setFirstName(firstName)
            self.txtFirstName.resignFirstResponder()
        })
    }
    
    fileprivate func updateLastName(_ lastName: String) {
        updateUserInformation(data: ["lastName": lastName as AnyObject], callback: {
            UserSessionManager.shared.user?.setLastName(lastName)
            self.txtLastName.resignFirstResponder()
        })
    }
    
    fileprivate func updatePhone(_ phone: String) {
        let prefix = (countryPhonePrefixPicker.text ?? "").replacingOccurrences(of: " ", with: "")
        let phoneNumber =  prefix + phone
        updateUserInformation(data: ["phoneMobile": phoneNumber as AnyObject], callback: {
            UserSessionManager.shared.user?.setPhone(phoneNumber)
            self.txtPhone.resignFirstResponder()
        })
    }
    
    func performValidationsOn( _ textField: UITextField) {
        textField.cleanError()
        
        switch textField {
        case txtFirstName:
            guard !(self.txtFirstName.text?.isEmpty() ?? true),
            (txtFirstName.text?.isShorterThan(257) ?? true) else {
                txtFirstName.displayError("first_name_not_empty".localized)
                break
            }
            updateUserInformation(txtFirstName)
        case txtLastName:
            guard !(self.txtLastName.text?.isEmpty() ?? true),
            (txtLastName.text?.isShorterThan(257) ?? true) else {
                txtLastName.displayError("last_name_not_empty".localized)
                break
            }
            
            updateUserInformation(txtLastName)
        case txtPhone:
            validateAndUpdatePhone()
    
        default:
            break
        }
    }
    
    fileprivate func validateAndUpdatePhone() {
        let prefix = countryPhonePrefixPicker.text!.replacingOccurrences(of: " ", with: "")
        let fullPhone = prefix + txtPhone.text!.replacingOccurrences(of: prefix, with: "")
        let result = fullPhone.isValidPhoneNumber()
        if result.isValid {
            txtPhone.text = result.number?.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            updateUserInformation(txtPhone)
        } else {
            txtPhone.displayError("phone_number_is_invalid".localized)
        }
    }
    
    fileprivate func updateUserInformation(data: [String: AnyObject], callback: @escaping () -> Void) {
        
        if !FloApiRequest.demoModeEnabled() {
            
            guard let user = UserSessionManager.shared.user else {
                return
            }
            
            showLoadingSpinner("please_wait".localized)
            
            FloApiRequest(
                controller: "v2/users/\(user.id)",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _ ) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    } else {
                        callback()
                    }
            }).secureFloRequest()
        } else {
            showFeatureNotSupportedInDemoModeAlert()
        }
    }
    
    fileprivate func updateUserInformation(_ sender: UITextField) {
        
        guard let text = sender.text, !text.isEmpty else {
            return
        }
        
        switch sender {
        case txtFirstName:
            updateFirstName(text)
        case txtLastName:
            updateLastName(text)
        case txtPhone:
            updatePhone(text)
        default:
            break
        }
    }
    
    @objc fileprivate func openCountryCodePicker() {
        let storyboard =  UIStoryboard(name: "Registration", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: PhonePrefixPickerViewController.storyboardId) as? PhonePrefixPickerViewController {
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
   
    // MARK: - Text field delegate
    
    override internal func textFieldDidEndEditing(_ textField: UITextField) {
        performValidationsOn(textField)
    }
   
    override public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: PhonePrefixPickerDelegate
    
    public func didSelectPhonePrefix(prefix: String) {
        countryPhonePrefixPicker.text = prefix
        validateAndUpdatePhone()
    }

}
