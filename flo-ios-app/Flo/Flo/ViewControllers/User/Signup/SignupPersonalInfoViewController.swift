//
//  SignupPersonalInfoViewController.swift
//  Flo
//
//  Created by Matias Paillet on 5/24/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class SignupPersonalInfoViewController: FloBaseViewController, SignUpStep, FloPickerDelegate,
    PhonePrefixPickerDelegate {
    
    @IBOutlet fileprivate weak var txtFirstName: UITextField!
    @IBOutlet fileprivate weak var txtLastName: UITextField!
    @IBOutlet fileprivate weak var txtPhoneNumber: UITextField!
    @IBOutlet fileprivate weak var txtCountry: UITextField!
    @IBOutlet fileprivate weak var checkAgreement: UIButton!
    @IBOutlet fileprivate weak var btnTermsAndConditions: UIButton!
    
    fileprivate var locales: [FloLocale]?
    fileprivate var countryPicker: FloPicker?
    fileprivate var selectedLocale: FloLocale?
    fileprivate var validator: Validator!
    fileprivate var countryPhonePrefixPicker: UILabel!
    
    public weak var delegate: SignupViewController?
    
    // MARK: Lifecycle
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch data
        getCountries()
        
        self.validator = Validator(objectsToValidate: controlsToValidate())
        
        configureView()
    }
    
    fileprivate func configureView() {
        
        // UI Customization
        txtCountry.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(openPicker))
        
        let underlinedTerms = NSAttributedString(string: "i_agree_with_the_terms_and_conditions".localized,
                                                      attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        countryPhonePrefixPicker = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: txtPhoneNumber.frame.height))
        countryPhonePrefixPicker.font = StyleHelper.font(sized: .medium)
        countryPhonePrefixPicker.backgroundColor = UIColor.clear
        countryPhonePrefixPicker.textColor = StyleHelper.colors.darkBlue
        countryPhonePrefixPicker.textAlignment = .center
        countryPhonePrefixPicker.text = "+1"
        txtPhoneNumber.addLeftView(
            countryPhonePrefixPicker,
            withTarget: self,
            andAction: #selector(openCountryCodePicker))
        btnTermsAndConditions.titleLabel?.attributedText = underlinedTerms
    }
    
    fileprivate func controlsToValidate() -> [NSObject] {
        return [txtFirstName, txtLastName, txtPhoneNumber, txtCountry, checkAgreement]
    }
    
    @objc fileprivate func openPicker() {
        txtCountry.becomeFirstResponder()
    }
    
    @objc fileprivate func openCountryCodePicker() {
        let storyboard =  UIStoryboard(name: "Registration", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: PhonePrefixPickerViewController.storyboardId) as? PhonePrefixPickerViewController {
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction public func changeCheck() {
        self.checkAgreement.isSelected = !self.checkAgreement.isSelected
        if self.checkAgreement.isSelected {
            validator.markAsValid(checkAgreement)
        } else {
            validator.markAsInvalid(checkAgreement)
        }
        checkValidationsAndUpdateUI()
    }
    
    fileprivate func getCountries() {
        FloApiRequest(
            controller: "v2/lists",
            method: .get,
            queryString: ["id": "country,region_us,region_ca,timezone_us,timezone_ca"],
            data: nil,
            done: ({ (error, data) in
                if error != nil {
                    return
                }
                
                var allLocales = [FloLocale]()
                if let dict = data as? NSDictionary, let list = dict["items"] as? [NSDictionary] {
                    allLocales = FloLocale.array(list)
                }
                self.locales = allLocales.sorted(by: { return FloLocale.compareTwoLocales($0, $1) })
                self.setupCountries(locales: self.locales!)
        })).unsecureFloRequest()
    }
    
    @IBAction public func openTermsAndConditions() {
        self.delegate?.openTermsAndConditions()
        if !self.checkAgreement.isSelected {
            self.changeCheck()
        }
    }
    
    // MARK: Country Picker
    fileprivate func setupCountries(locales: [FloLocale]) {
        self.locales = locales
        var displayNames = [String?]()
        for locale in locales {
            displayNames.append(locale.name)
        }
        self.countryPicker = FloPicker(textField: self.txtCountry, withData: displayNames as [AnyObject])
        self.countryPicker?.setPlaceholder("select_a_country".localized)
        self.countryPicker?.shouldDisplayCancelButton = false
        self.countryPicker?.delegate = self
    }
    
    // MARK: FloPickerDelegate
    
    func pickerDidSelectRow(_ picker: FloPicker, row: Int) {
        guard let count = self.locales?.count, count > row else {
            return
        }
        self.txtCountry.text = self.locales?[row].name
        self.selectedLocale = self.locales?[row]
        
        if self.selectedLocale != nil {
            self.validator.markAsValid(txtCountry)
        } else {
            self.validator.markAsInvalid(txtCountry)
        }
        checkValidationsAndUpdateUI()
        
        if let locale = self.selectedLocale?.id,
            let prefix = CountryPhonePrefixHelper.getPrefixForCountry(locale.uppercased()) {
            countryPhonePrefixPicker.text = prefix
        }
        
    }
    
    // MARK: SignUpStep
    
    public func performIsValidCheck(_ andThen:@escaping (_ success: Bool) -> Void) {
        
        let controls = controlsToValidate()
        for c in controls {
            if let control = c as? UITextField, !self.performValidationsOn(control) {
                return
            }
        }
        
        if !validator.allChecksPassed() {
            delegate?.disableNextStep()
            return
        }
        
        let prefix = countryPhonePrefixPicker.text!.replacingOccurrences(of: " ", with: "")
        let fullPhone = prefix + txtPhoneNumber.text!.replacingOccurrences(of: prefix, with: "")
        SignUpBuilder.shared.setFirstName(
            txtFirstName.text!,
            lastName: txtLastName.text!,
            phone: fullPhone,
            andCountry: self.selectedLocale!)
        
        andThen(true)
    }
    
    // MARK: UITextFieldDelegate and Validations
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _  = performValidationsOn(textField)
        return
    }
    
    func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtFirstName:
            guard !(self.txtFirstName.text?.isEmpty() ?? true) else {
                txtFirstName.displayError("required_field".localized)
                validator.markAsInvalid(txtFirstName)
                break
            }
            validator.markAsValid(txtFirstName)
            
        case txtLastName:
            guard !(self.txtLastName.text?.isEmpty() ?? true) else {
                txtLastName.displayError("required_field".localized)
                validator.markAsInvalid(txtLastName)
                break
            }
            validator.markAsValid(txtLastName)
            
        case txtPhoneNumber:
            
            let prefix = countryPhonePrefixPicker.text!.replacingOccurrences(of: " ", with: "")
            let fullPhone = prefix + txtPhoneNumber.text!.replacingOccurrences(of: prefix, with: "")
            let result = fullPhone.isValidPhoneNumber()
            if result.isValid {
                txtPhoneNumber.text = result.number?.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                validator.markAsValid(txtPhoneNumber)
            } else {
                txtPhoneNumber.displayError("phone_number_is_invalid".localized)
                validator.markAsInvalid(txtPhoneNumber)
            }
            
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
    
    // MARK: PhonePrefixPickerDelegate
    
    public func didSelectPhonePrefix(prefix: String) {
        countryPhonePrefixPicker.text = prefix
    }
    
}
