//
//  LocationAddressViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/12/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationAddressViewController: BaseAddLocationStepViewController, FloPickerDelegate {
    
    @IBOutlet fileprivate weak var txtAddressLine1: UITextField!
    @IBOutlet fileprivate weak var txtAddressLine2: UITextField!
    @IBOutlet fileprivate weak var txtCountry: UITextField!
    @IBOutlet fileprivate weak var txtCity: UITextField!
    @IBOutlet fileprivate weak var txtState: UITextField!
    @IBOutlet fileprivate weak var txtStateFreeText: UITextField!
    @IBOutlet fileprivate weak var txtZipcode: UITextField!
    @IBOutlet fileprivate weak var txtTimezone: UITextField!
    
    fileprivate static let kMaxLengthAddress = 256
    
    fileprivate var validator: Validator!
    fileprivate var countries: [FloLocale]?
    fileprivate var countryPicker: FloPicker?
    fileprivate var timezones: [LocaleTimezone]?
    fileprivate var timezonePicker: FloPicker?
    fileprivate var states: [LocaleRegion]?
    fileprivate var statePicker: FloPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disableNextStep()
        self.validator = Validator(objectsToValidate: textFieldsToValidate())
        setupCountries()
        setupStates()
        setupTimezones()
        prefillWithBuilderInfo()
    }
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtAddressLine1, txtCity, txtZipcode, txtCountry, txtState, txtTimezone]
    }
    
    override public func prefillWithBuilderInfo() {
        if let address = AddLocationBuilder.shared.address {
            txtAddressLine1.text = address
            _ = performValidationsOn(txtAddressLine1)
        }
        
        if let address2 = AddLocationBuilder.shared.address2 {
            txtAddressLine2.text = address2
            _ = performValidationsOn(txtAddressLine2)
        }
        
        if let city = AddLocationBuilder.shared.city {
            txtCity.text = city
            _ = performValidationsOn(txtCity)
        }
        
        if let zipcode = AddLocationBuilder.shared.postalCode {
            txtZipcode.text = zipcode
            _ = performValidationsOn(txtZipcode)
        }
        
        if let country = AddLocationBuilder.shared.selectedCountry {
            txtCountry.text = country.name
            validator.markAsValid(txtCountry)
        }
        
        if let region = AddLocationBuilder.shared.selectedState {
            txtState.text = region.name
            validator.markAsValid(txtState)
        }
        
        if !txtStateFreeText.isHidden, let regionFreeText = AddLocationBuilder.shared.state {
            txtStateFreeText.text = regionFreeText
            validator.markAsValid(txtStateFreeText)
        }
        
        if let timezone = AddLocationBuilder.shared.selectedTimezone {
            txtTimezone.text = timezone.name
            validator.markAsValid(txtTimezone)
        }
        
        checkValidationsAndUpdateUI()
    }
    
    // MARK: Country Picker
    
    fileprivate func setupCountries() {
        self.countries = AddLocationBuilder.shared.countries
        var displayNames = [String?]()
        for locale in self.countries! {
            displayNames.append(locale.name)
        }
        self.countryPicker = FloPicker(textField: self.txtCountry, withData: displayNames as [AnyObject])
        self.countryPicker?.setPlaceholder("select_a_country".localized)
        self.countryPicker?.shouldDisplayCancelButton = false
        self.countryPicker?.delegate = self
        txtCountry.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openCountryPicker))
    }
    
    @objc fileprivate func openCountryPicker() {
        txtCountry.becomeFirstResponder()
    }
    
    // MARK: State Picker
    fileprivate func cleanStateField() {
        self.txtState.text = ""
        self.txtStateFreeText.text = ""
        self.txtState.rightView = nil
        validator.markAsInvalid(txtState)
        checkValidationsAndUpdateUI()
    }
    
    fileprivate func setupStates() {
        cleanStateField()
        
        guard let states = AddLocationBuilder.shared.selectedCountry?.regions, states.count > 0 else {
            self.txtStateFreeText.isHidden = false
            return
        }
        
        self.txtStateFreeText.isHidden = true
        self.states = states
        var displayNames = [String?]()
        for region in self.states! {
            displayNames.append(region.name)
        }
        self.statePicker = FloPicker(textField: self.txtState, withData: displayNames as [AnyObject])
        self.statePicker?.setPlaceholder("state".localized)
        self.statePicker?.shouldDisplayCancelButton = false
        self.statePicker?.delegate = self
        DispatchQueue.main.async { //Do this to force screen redraw in an edge case.
            self.txtState.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openStatePicker))
        }
    }
    
    @objc fileprivate func openStatePicker() {
        txtState.becomeFirstResponder()
    }
    
    // MARK: Timezone Picker
    
    fileprivate func cleanTimeZoneField() {
        self.txtTimezone.text = ""
        self.txtTimezone.rightView = nil
        validator.markAsInvalid(txtTimezone)
        checkValidationsAndUpdateUI()
    }
    
    fileprivate func setupTimezones() {
        cleanTimeZoneField()
        
        guard let timezones = AddLocationBuilder.shared.selectedCountry?.timezones else {
            return
        }
        
        self.timezones = timezones
        var displayNames = [String?]()
        for timezone in self.timezones! {
            displayNames.append(timezone.name)
        }
        self.timezonePicker = FloPicker(textField: self.txtTimezone, withData: displayNames as [AnyObject])
        self.timezonePicker?.setPlaceholder("timezone".localized)
        self.timezonePicker?.shouldDisplayCancelButton = false
        self.timezonePicker?.delegate = self
        DispatchQueue.main.async { //Do this to force screen redraw in an edge case.
            self.txtTimezone.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openTimezonePicker))
        }
    }
    
    @objc fileprivate func openTimezonePicker() {
        txtTimezone.becomeFirstResponder()
    }
    
    fileprivate func resetStateAndTimezonePickers() {
        AddLocationBuilder.shared.changeSelectedRegion(nil)
        setupStates()
        AddLocationBuilder.shared.changeSelectedTimezone(nil)
        setupTimezones()
    }
    
    // MARK: FloPickerDelegate

    func pickerDidSelectRow(_ picker: FloPicker, row: Int) {
        
        switch picker {
        case countryPicker:
            guard let count = self.countries?.count, count > row else {
                return
            }
            self.txtCountry.text = self.countries?[row].name
            AddLocationBuilder.shared.changeSelectedCountry(self.countries![row]) { (success) in
                if success {
                    self.resetStateAndTimezonePickers()
                }
            }
            AddLocationBuilder.shared.changeSelectedRegion(nil)
            cleanStateField()
            AddLocationBuilder.shared.changeSelectedTimezone(nil)
            cleanTimeZoneField()
            
            if AddLocationBuilder.shared.selectedCountry != nil {
                self.validator.markAsValid(txtCountry)
            } else {
                self.validator.markAsInvalid(txtCountry)
            }
            self.checkValidationsAndUpdateUI()
            
        case statePicker:
            guard let count = self.states?.count, count > row else {
                return
            }
            self.txtState.text = self.states?[row].name
            AddLocationBuilder.shared.changeSelectedRegion(self.states![row])
            if AddLocationBuilder.shared.selectedState != nil {
                self.validator.markAsValid(txtState)
            } else {
                self.validator.markAsInvalid(txtState)
            }
            self.checkValidationsAndUpdateUI()
            
        case timezonePicker:
            guard let count = self.timezones?.count, count > row else {
                return
            }
            self.txtTimezone.text = self.timezones?[row].name
            AddLocationBuilder.shared.changeSelectedTimezone(self.timezones![row])
            if AddLocationBuilder.shared.selectedTimezone != nil {
                self.validator.markAsValid(txtTimezone)
            } else {
                self.validator.markAsInvalid(txtTimezone)
            }
            self.checkValidationsAndUpdateUI()
            
        default:
            break
        }
    }
    
    // MARK: Validations
    
    override func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtAddressLine1:
            guard !(self.txtAddressLine1.text?.isEmpty() ?? true) else {
                txtAddressLine1.displayError("address_not_empty".localized)
                validator.markAsInvalid(txtAddressLine1)
                break
            }
            
            validator.markAsValid(txtAddressLine1)
        case txtCity:
            guard !(self.txtCity.text?.isEmpty() ?? true) else {
                txtCity.displayError("city_not_empty".localized)
                validator.markAsInvalid(txtCity)
                break
            }
            
            validator.markAsValid(txtCity)
        case txtZipcode:
            guard !(self.txtZipcode.text?.isEmpty() ?? true) else {
                txtZipcode.displayError("zipcode_not_empty".localized)
                validator.markAsInvalid(txtZipcode)
                break
            }
            
            validator.markAsValid(txtZipcode)
        case txtStateFreeText:
            guard !(self.txtStateFreeText.text?.isEmpty() ?? true) else {
                txtStateFreeText.displayError("state_not_empty".localized)
                validator.markAsInvalid(txtState)
                break
            }
            
            validator.markAsValid(txtState)
        default:
            break
        }
        
        checkValidationsAndUpdateUI()
        
        return true
    }
    
    fileprivate func checkValidationsAndUpdateUI() {
        if validator.allChecksPassed() {
            self.enableNextStep()
        } else {
            self.disableNextStep()
        }
    }
    
    // MARK: UITextFieldDelegate and Validations
    
    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
            guard let textFieldText = textField.text,
                let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                    return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= LocationAddressViewController.kMaxLengthAddress
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
            switch textField {
            case txtAddressLine1:
                AddLocationBuilder.shared.set(address: txtAddressLine1.text!)
            case txtAddressLine2:
                AddLocationBuilder.shared.set(address2: txtAddressLine2.text!)
            case txtCity:
                AddLocationBuilder.shared.set(city: txtCity.text!)
            case txtStateFreeText:
                AddLocationBuilder.shared.set(state: txtStateFreeText.text!)
            case txtZipcode:
                AddLocationBuilder.shared.set(zipcode: txtZipcode.text!)
            default:
                break
            }
    }
    
    // MARK: Actions
    
    @IBAction public func goNext() {
        let controls = textFieldsToValidate()
        for c in controls {
            if !self.performValidationsOn(c) {
                return
            }
        }
        
        if !validator.allChecksPassed() {
            self.disableNextStep()
            return
        }
        
        guard let countryName = AddLocationBuilder.shared.selectedCountry?.name else {
            self.disableNextStep()
            return
        }
        
        let state = txtStateFreeText.isHidden ? AddLocationBuilder.shared.selectedState?.name : txtStateFreeText.text
        if !txtStateFreeText.isHidden { AddLocationBuilder.shared.freeTextState = txtStateFreeText.text }
        
        guard let stateName = state else {
            self.disableNextStep()
            return
        }
        
        guard let timezoneName = AddLocationBuilder.shared.selectedTimezone?.id else {
            self.disableNextStep()
            return
        }
        
        AddLocationBuilder.shared.set(address: txtAddressLine1.text!,
                                      address2: txtAddressLine2.text,
                                      country: countryName,
                                      city: txtCity.text!,
                                      state: stateName,
                                      zipcode: txtZipcode.text!,
                                      timezone: timezoneName)
        
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationSizeViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
}
