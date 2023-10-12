//
//  LocationTypeViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/6/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationTypeViewController: BaseAddLocationStepViewController {
    
    fileprivate let kCellHeight: CGFloat = 64
    
    fileprivate var residenceTypeOptions: [ResidenceType] = []
    fileprivate var residenceTypeSelected: ResidenceType?
    
    @IBOutlet fileprivate weak var residenceTypeTableView: UITableView!
    @IBOutlet fileprivate weak var residenceTypeTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var btnSingleFamilyApt: FloOptionButton!
    @IBOutlet fileprivate weak var btnCondo: FloOptionButton!
    @IBOutlet fileprivate weak var btnApt: FloOptionButton!
    @IBOutlet fileprivate weak var btnOtherType: FloOptionButton!
    
    fileprivate var aptTypeValidator: SingleChoiceValidator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize builder for the entire flow
        AddLocationBuilder.shared.start()
        
        self.aptTypeValidator = SingleChoiceValidator(objectsToValidate:
            [btnSingleFamilyApt, btnCondo, btnApt, btnOtherType])
        
        self.residenceTypeOptions = ListsManager.shared.getResidenceTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.residenceTypeOptions = types
                self.updateResidenceTypeConstraints()
            }
        })
        
        updateResidenceTypeConstraints()
        checkValidationsAndUpdateUI()
    }
    
    fileprivate func updateResidenceTypeConstraints() {
        self.residenceTypeTableViewHeight.constant = CGFloat(self.residenceTypeOptions.count) * self.kCellHeight
        self.residenceTypeTableView.reloadData()
    }
    
    fileprivate func checkValidationsAndUpdateUI() {
        if aptTypeValidator!.allChecksPassed() && residenceTypeSelected != nil {
            self.enableNextStep()
        } else {
            self.disableNextStep()
        }
    }
    
    // MARK: Actions
    
    @IBAction public func goNext() {
        guard let selectedType = self.aptTypeValidator?.getSelectedOption()?.backendIdentifier,
            let selectedUse = self.residenceTypeSelected?.id else {
                return
        }
        
        AddLocationBuilder.shared.set(locationType: selectedType, locationUse: selectedUse)
        
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationNameViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
    @IBAction public func didPressTypeButton(_ button: FloOptionButton) {
        self.aptTypeValidator?.selectOption(button)
        checkValidationsAndUpdateUI()
    }
}

extension LocationTypeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return residenceTypeOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: FloOptionButtonCell.storyboardId) as? FloOptionButtonCell {
            cell.configure(
                name: residenceTypeOptions[indexPath.row].name,
                selected: residenceTypeSelected?.id == residenceTypeOptions[indexPath.row].id) {
                    self.residenceTypeSelected = self.residenceTypeOptions[indexPath.row]
                    self.residenceTypeTableView.reloadData()
                    self.checkValidationsAndUpdateUI()
            }
            return cell
        }

        return UITableViewCell()
    }
}
