//
//  LocationHomeInsuranceViewController.swift
//  Flo
//
//  Created by Josefina Perez on 19/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationHomeInsuranceViewController: BaseAddLocationStepViewController {
    
    fileprivate static let kOptionsContainerHeight: CGFloat = 306
    
    @IBOutlet fileprivate weak var txtInsurenceProvider: UITextField!
    @IBOutlet fileprivate weak var btnYes: FloOptionButton!
    @IBOutlet fileprivate weak var btnNo: FloOptionButton!
    @IBOutlet fileprivate weak var btnClaim1: FloOptionButton!
    @IBOutlet fileprivate weak var btnClaim2: FloOptionButton!
    @IBOutlet fileprivate weak var btnClaim3: FloOptionButton!
    @IBOutlet fileprivate weak var btnClaim4: FloOptionButton!
    @IBOutlet fileprivate weak var optionsContainerHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var optionsContainerView: UIView!
    
    fileprivate var waterDamageValidator: SingleChoiceValidator?
    fileprivate var claimAmountValidator: SingleChoiceValidator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.waterDamageValidator = SingleChoiceValidator(objectsToValidate: [btnYes, btnNo])
        
        self.claimAmountValidator = SingleChoiceValidator(objectsToValidate:
            [btnClaim1, btnClaim2, btnClaim3, btnClaim4])
        
        self.optionsContainerHeight.constant = 0
        
        prefillWithBuilderInfo()
    }
    
    override func prefillWithBuilderInfo() {
        txtInsurenceProvider.text = AddLocationBuilder.shared.homeownersInsurance
        
        if let claim = AddLocationBuilder.shared.hasPastWaterDamage {
            self.waterDamageValidator?.selectOption(claim ? btnYes : btnNo)
            
            if let amount = AddLocationBuilder.shared.pastWaterDamageClaimAmount {
                self.optionsContainerHeight.constant = LocationHomeInsuranceViewController.kOptionsContainerHeight
                self.claimAmountValidator?.selectOption(backendIdentifier: amount)
            }
            
            configureClaimAmount(hasPastWaterDamage: claim, animated: false)
        }
    }
    
    public func configureClaimAmount(hasPastWaterDamage: Bool, animated: Bool) {
        if hasPastWaterDamage && AddLocationBuilder.shared.selectedCountry?.id == "us" {
            self.optionsContainerHeight.constant = LocationHomeInsuranceViewController.kOptionsContainerHeight
            
            if let selectedOption = self.claimAmountValidator?.getSelectedOption() {
                self.claimAmountValidator?.selectOption(selectedOption)
                let amount = self.claimAmountValidator?.getSelectedOption()?.backendIdentifier
                AddLocationBuilder.shared.set(claimedAmount: amount)
            }
            
            self.view.setNeedsUpdateConstraints()
            self.view.setNeedsLayout()
            
            UIView.animate(withDuration: animated ? 0.5 : 0) {
                self.optionsContainerView.alpha = 1
            }
        } else {
            AddLocationBuilder.shared.set(claimedAmount: nil)
            
            self.optionsContainerHeight.constant = 0
            UIView.animate(
                withDuration: animated ? 0.5 : 0,
                animations: {
                    self.optionsContainerView.alpha = 0
                    self.view.layoutIfNeeded()
            },
                completion: { (_) in
                    self.view.setNeedsUpdateConstraints()
                    self.view.setNeedsLayout()
            })
        }
    }
    
    // MARK: UITextFieldDelegate
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField == txtInsurenceProvider {
            AddLocationBuilder.shared.set(homeInsurance: txtInsurenceProvider.text)
        }
    }
    
    // MARK: Actions
    
    @IBAction public func didPressWaterDamageButton(_ button: FloOptionButton) {
        self.waterDamageValidator?.selectOption(button)
        
        let hasPastWaterDamage = self.waterDamageValidator?.getSelectedOption() == btnYes
        AddLocationBuilder.shared.set(hasPastWaterDamage: hasPastWaterDamage)
        
        configureClaimAmount(hasPastWaterDamage: button == btnYes, animated: true)
    }
    
    @IBAction public func didPressClaimAmountButton(_ button: FloOptionButton) {
        self.claimAmountValidator?.selectOption(button)
        let amount = button.backendIdentifier
        AddLocationBuilder.shared.set(claimedAmount: amount)
    }
    
    @IBAction fileprivate func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationWaterUtilityViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }

}
