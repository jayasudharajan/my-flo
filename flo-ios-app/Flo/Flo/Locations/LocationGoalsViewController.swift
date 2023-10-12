//
//  LocationGoalsViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/18/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationGoalsViewController: BaseAddLocationStepViewController {
    
    fileprivate static let kGallonsPerPerson = 80
    fileprivate static let kLitersPerPerson = 300
    fileprivate static let kMaxNumOfNumericChars = 5
    
    @IBOutlet fileprivate weak var lblNumberOfPeople: UILabel!
    @IBOutlet fileprivate weak var lblDescription: UILabel!
    @IBOutlet fileprivate weak var txtIndividual: UITextField!
    @IBOutlet fileprivate weak var txtTotal: UITextField!
    
    fileprivate var individualGoal = 0
    fileprivate var occupants = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        //Set defaults
        AddLocationBuilder.shared.set(gallonsPerDayGoal: Double(self.individualGoal))
        
        prefillWithBuilderInfo()
    }
    
    fileprivate func configureUI() {
        let isImperial = MeasuresHelper.getMeasureSystem() == .imperial
        let format = "set_a_target_for_daily_water_use_people_use_number_per_day_on_average".localized
        let param = (isImperial ? "80-100 " : "320-400 ") + MeasuresHelper.unitName(for: .volume)
        self.lblDescription.text = String(format: format, param)
        
        let string = "units_per_day".localized + "   " //add this for right padding
        self.txtIndividual.addRightText(String(format: string, MeasuresHelper.unitAbbreviation(for: .volume)))
        self.txtTotal.addRightText(String(format: string, MeasuresHelper.unitAbbreviation(for: .volume)))
        
        if let occupants = AddLocationBuilder.shared.occupants {
            self.occupants = occupants
            self.lblNumberOfPeople.text = "\(occupants) " + "people".localized
            
            let defaultPerPerson = isImperial ? LocationGoalsViewController.kGallonsPerPerson : LocationGoalsViewController.kLitersPerPerson
            self.individualGoal = defaultPerPerson
            self.txtIndividual.text = "\(Int(defaultPerPerson))"
            self.txtTotal.text =  "\(Int(defaultPerPerson * occupants))"
        }
        
        self.txtIndividual.delegate = self
        self.txtTotal.delegate = self
    }
    
    override func prefillWithBuilderInfo() {
        if let goal = AddLocationBuilder.shared.gallonsPerDayGoal {
            self.individualGoal = Int(goal)
            self.txtIndividual.text = "\(self.individualGoal)"
            self.txtTotal.text = "\(Int(self.individualGoal * self.occupants))"
        }
    }
    
    // MARK: UITextFieldDelegate
    
    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        
        if newString.count > LocationGoalsViewController.kMaxNumOfNumericChars { //max 9999
            return false
        }
        
        if newString.isEmpty { //To allow last character to be deleted
            newString = "1"
        }
        
        switch textField {
        case txtIndividual:
            if let value = Int(newString) {
                self.individualGoal = value > 1 ? value : 1
                self.txtTotal.text = "\(self.individualGoal * self.occupants)"
                
                AddLocationBuilder.shared.set(gallonsPerDayGoal: Double(self.individualGoal))
                
            } else {
                return false
            }
        case txtTotal:
            if let value = Int(newString) {
                let newValue = Int(value / self.occupants)
                self.individualGoal = newValue > 1 ? newValue : 1
                self.txtIndividual.text = "\(self.individualGoal)"
                
                AddLocationBuilder.shared.set(gallonsPerDayGoal: Double(self.individualGoal))
                
            } else {
                return false
            }
        default:
            break
        }
        return true
    }
    
    // MARK: Actions
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationHomeInsuranceViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
}
