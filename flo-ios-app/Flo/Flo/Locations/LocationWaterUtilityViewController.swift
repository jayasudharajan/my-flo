//
//  LocationWaterUtilityViewController.swift
//  Flo
//
//  Created by Josefina Perez on 19/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationWaterUtilityViewController: BaseAddLocationStepViewController {
    
    @IBOutlet fileprivate weak var txtWaterUtility: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prefillWithBuilderInfo()
    }
    
    override func prefillWithBuilderInfo() {
        if let waterUtility = AddLocationBuilder.shared.waterUtility {
            txtWaterUtility.text = waterUtility
        }
    }
    
    // MARK: UITextFieldDelegate
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        goNext()
        return true
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        AddLocationBuilder.shared.set(waterUtility: txtWaterUtility.text ?? "")
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func goNext() {
        let result = AddLocationBuilder.shared.build()
        if result.error != nil {
            LoggerHelper.log(result.error?.localizedDescription ?? "Error on AddLocationBuilder.build()", level: .error)
            return
        }
        
        showLoadingSpinner("please_wait".localized)
        
        FloApiRequest(
            controller: "v2/locations",
            method: .post,
            queryString: nil,
            data: result.result,
            done: { (error, data) in
                self.hideLoadingSpinner()
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    if let location = LocationModel(data) {
                        LocationsManager.shared.addLocationLocally(location, asSelected: true)
                    }
                    if let dashboardVC = self.navigationController?.viewControllers.first as? DashboardViewController {
                        dashboardVC.refreshLocation()
                    }
                    self.showPopup(
                        title: "home_added".localized,
                        description: "your_home_was_added_successfully".localized,
                        options: [
                            AlertPopupOption(title: "continue_".localized, type: .normal, action: {
                                self.navigationController?.popToRootViewController(animated: true)
                            })
                        ]
                    )
                }
            }
        ).secureFloRequest()
    }
}
