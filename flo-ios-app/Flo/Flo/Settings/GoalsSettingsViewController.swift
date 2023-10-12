//
//  GoalsSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 16/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class GoalsSettingsViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var txtIndividual: UITextField!
    @IBOutlet fileprivate weak var txtTotal: UITextField!
    @IBOutlet fileprivate weak var lblTotal: UILabel!
    
    public var location: LocationModel?
    
    fileprivate static let kMaxNumOfNumericChars = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        setupNavBarWithBack(andTitle: "goals".localized, tint: StyleHelper.colors.white,
                            titleColor: StyleHelper.colors.white)
        
        let string = "units_per_day".localized + "   "
        txtIndividual.addRightText(String(format: string, MeasuresHelper.unitAbbreviation(for: .volume)))
        txtTotal.addRightText(String(format: string, MeasuresHelper.unitAbbreviation(for: .volume)))
        
        if location == nil {
            self.location = LocationsManager.shared.selectedLocation
        }
        
        AddLocationBuilder.shared.start({ _ in
            if self.location != nil {
                AddLocationBuilder.shared.startWithLocation(self.location!)
            } else {
                AddLocationBuilder.shared.startWithCurrentLocation()
            }
        })
        
        fillWithLocationInfo()
    }
    
    fileprivate func fillWithLocationInfo() {
        guard let location = self.location else {
            return
        }
        
        let totalGoal = MeasuresHelper.adjust(location.gallonsPerDayGoal, ofType: .volume)
        txtTotal.text = String(format: "%.0f", totalGoal.rounded(.toNearestOrAwayFromZero))
        txtIndividual.text = String(format: "%.0f", (totalGoal / Double(location.occupants)).rounded(.toNearestOrAwayFromZero))
        
        lblTotal.text = "\("total".localized) (\(location.occupants) \("people".localized))"
    }
    
    fileprivate func updateGoals() {
        
        let result = AddLocationBuilder.shared.build(update: true)
        if result.error != nil {
            LoggerHelper.log(result.error?.localizedDescription ?? "Error on AddLocationBuilder.build()", level: .error)
            return
        }
        
        guard let selectedLocationId = (self.location?.id ?? UserSessionManager.shared.selectedLocationId) else {
            return
        }
        
        FloApiRequest(
            controller: "v2/locations/\(selectedLocationId)",
            method: .post,
            queryString: nil,
            data: result.result,
            done: { (error, _ ) in
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    LocationsManager.shared.updateLocationLocally(
                        id: selectedLocationId,
                        LocationModel(AddLocationBuilder.shared)
                    )
                }
            }
        ).secureFloRequest()
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: UITextFieldDelegate
    
    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        
        if newString.count > GoalsSettingsViewController.kMaxNumOfNumericChars {
            return false
        }
        
        if newString.isEmpty {
            newString = "1"
        }
        
        guard let occupants = self.location?.occupants else {
            return false
        }
        
        switch textField {
        case txtIndividual:
            if let value = Int(newString) {
                let individualGoal = value > 1 ? value : 1
                let totalGoal = Double(individualGoal * occupants).rounded(.toNearestOrAwayFromZero)
                txtTotal.text = String(format: "%.0f", totalGoal)
                
                AddLocationBuilder.shared.set(gallonsPerDayGoal: MeasuresHelper.adjust(
                    totalGoal,
                    ofType: .volume,
                    from: MeasuresHelper.getMeasureSystem(),
                    to: .imperial
                ))
            } else {
                return false
            }
        case txtTotal:
            if let value = Double(newString) {
                let totalGoal = value > 1 ? value : 1
                let individualGoal = (totalGoal / Double(occupants)).rounded(.toNearestOrAwayFromZero)
                txtIndividual.text = String(format: "%.0f", individualGoal)
                
                AddLocationBuilder.shared.set(gallonsPerDayGoal: MeasuresHelper.adjust(
                    totalGoal,
                    ofType: .volume,
                    from: MeasuresHelper.getMeasureSystem(),
                    to: .imperial
                ))
            } else {
                return false
            }
        default:
            break
        }
        return true
    }
    
    override public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        _ = super.textFieldShouldEndEditing(textField)
        
        guard !FloApiRequest.demoModeEnabled() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showFeatureNotSupportedInDemoModeAlert()
            }
            return true
        }
        
        updateGoals()
        return true
    }
}
