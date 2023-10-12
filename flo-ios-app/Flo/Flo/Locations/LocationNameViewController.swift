//
//  LocationNameViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/12/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationNameViewController: BaseAddLocationStepViewController {
    
    fileprivate static let kMaxLengthHomeNickname = 24
    
    @IBOutlet fileprivate weak var txtNickname: UITextField!
    
    fileprivate var validator: Validator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disableNextStep()
        self.validator = Validator(objectsToValidate: textFieldsToValidate())
        self.txtNickname.delegate = self
        prefillWithBuilderInfo()
    }
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtNickname]
    }
    
    override public func prefillWithBuilderInfo() {
        if let nickname = AddLocationBuilder.shared.nickname {
            txtNickname.text = nickname
            _ = performValidationsOn(txtNickname)
        }
    }
    
    // MARK: Actions
    
    @IBAction public func goNext() {
        let textFields = textFieldsToValidate()
        for txt in textFields {
            if !self.performValidationsOn(txt) {
                return
            }
        }
        
        if !validator.allChecksPassed() {
            self.disableNextStep()
            return
        }
        
        AddLocationBuilder.shared.set(nickname: txtNickname.text!)
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationAddressViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
    // MARK: UITextFieldDelegate and Validations
    
    override public func textFieldShouldReturn(_ textField: UITextField) -> Bool {    
        goNext()
        return true
    }
    
    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == txtNickname {
            guard let textFieldText = textField.text,
                let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                    return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= LocationNameViewController.kMaxLengthHomeNickname
        }
        return true
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField == txtNickname {
            AddLocationBuilder.shared.set(nickname: txtNickname.text!)
        }
    }
    
    override func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtNickname:
            let nickname = txtNickname.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if nickname.isEmpty {
                txtNickname.displayError("nickname_not_empty".localized)
                validator.markAsInvalid(txtNickname)
            } else if !nickname.isShorterThan(257) {
                txtNickname.displayError("nickname_too_long".localized)
                validator.markAsInvalid(txtNickname)
            } else if !LocationsManager.shared.locations.filter({ (location) -> Bool in
                return location.nickname.lowercased() == nickname.lowercased()
            }).isEmpty {
                txtNickname.displayError("you_already_have_a_home_with_that_name".localized)
                validator.markAsInvalid(txtNickname)
            } else {
                validator.markAsValid(txtNickname)
            }
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
    
    fileprivate func checkLocationNameIsUnique(_ name: String?) -> Bool {
        guard var nickname = name else {
            return false
        }
        
        nickname = nickname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let locations = LocationsManager.shared.locations
        if locations.isEmpty {
            return true
        }
        
        return locations.filter {
            $0.nickname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == nickname
        }.count == 0
    }
}
