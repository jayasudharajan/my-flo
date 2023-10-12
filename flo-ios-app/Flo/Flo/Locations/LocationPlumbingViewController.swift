//
//  LocationPlumbingViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/14/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationPlumbingViewController: BaseAddLocationStepViewController {
    
    fileprivate let kCellHeight: CGFloat = 64
    
    fileprivate var pipeTypeOptions: [PipeType] = []
    fileprivate var pipeTypeSelected: PipeType?
    
    @IBOutlet fileprivate weak var pipeTypeTableView: UITableView!
    @IBOutlet fileprivate weak var pipeTypeTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var knowsShutoffYes: FloOptionButton!
    @IBOutlet fileprivate weak var knowsShutoffNo: FloOptionButton!
    @IBOutlet fileprivate weak var knowsShutoffNotSure: FloOptionButton!
    
    @IBOutlet fileprivate weak var sourceCityWater: FloOptionButton!
    @IBOutlet fileprivate weak var sourceWell: FloOptionButton!
    
    fileprivate var knowsShutoffValidator: SingleChoiceValidator?
    fileprivate var sourceValidator: SingleChoiceValidator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.knowsShutoffValidator = SingleChoiceValidator(
            objectsToValidate: [knowsShutoffYes, knowsShutoffNo, knowsShutoffNotSure])
        
        self.sourceValidator = SingleChoiceValidator(objectsToValidate: [sourceCityWater, sourceWell])
        
        self.pipeTypeOptions = ListsManager.shared.getPipeTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.pipeTypeOptions = types
                self.prefillWithBuilderInfo()
            }
        })
        
        prefillWithBuilderInfo()
        
        configureNextButton(isEnabled: shouldEnableNextButton())
    }
    
    override func prefillWithBuilderInfo() {
        
        if let plumbing = AddLocationBuilder.shared.plumbingType {
            self.pipeTypeSelected = self.pipeTypeOptions.first(where: { $0.id == plumbing })
        }
        self.pipeTypeTableViewHeight.constant = CGFloat(self.pipeTypeOptions.count) * self.kCellHeight
        self.pipeTypeTableView.reloadData()
        
        if let knows = AddLocationBuilder.shared.waterShutoffKnown {
            let control = knows == knowsShutoffYes.backendIdentifier ? knowsShutoffYes
                : knows == knowsShutoffNo.backendIdentifier ? knowsShutoffNo : knowsShutoffNotSure
            self.knowsShutoffValidator?.selectOption(control!)
        }
        
        if let source = AddLocationBuilder.shared.waterSource {
            let control = source == sourceCityWater.backendIdentifier ? sourceCityWater : sourceWell
            self.sourceValidator?.selectOption(control!)
        }
    }
    
     public func shouldEnableNextButton() -> Bool {
        return (pipeTypeSelected != nil && knowsShutoffValidator?.getSelectedOption() != nil
        && sourceValidator?.getSelectedOption() != nil)
    }
    
    // MARK: Actions
    
    @IBAction public func didPressKnowsShutoffButton(_ button: FloOptionButton) {
        self.knowsShutoffValidator?.selectOption(button)
        
        guard let knowsShutoff = button.backendIdentifier else { return }
        AddLocationBuilder.shared.set(waterShutoffKnown: knowsShutoff)
        
        configureNextButton(isEnabled: shouldEnableNextButton())
    }
    
    @IBAction public func didPressSourceButton(_ button: FloOptionButton) {
        self.sourceValidator?.selectOption(button)
        
        guard let source = button.backendIdentifier else { return }
        AddLocationBuilder.shared.set(waterSource: source)
        
        configureNextButton(isEnabled: shouldEnableNextButton())
    }
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationAmenitiesViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
}

extension LocationPlumbingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pipeTypeOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: FloOptionButtonCell.storyboardId) as? FloOptionButtonCell {
            cell.configure(
                name: pipeTypeOptions[indexPath.row].name,
                selected: pipeTypeSelected?.id == pipeTypeOptions[indexPath.row].id) {
                    self.pipeTypeSelected = self.pipeTypeOptions[indexPath.row]
                    self.pipeTypeTableView.reloadData()
                    AddLocationBuilder.shared.set(plumbingType: self.pipeTypeSelected!.id)
                    self.configureNextButton(isEnabled: self.shouldEnableNextButton())
            }
            return cell
        }

        return UITableViewCell()
    }
}
