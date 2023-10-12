//
//  LocationNumberOfPeopleViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/18/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class LocationNumberOfPeopleViewController: BaseAddLocationStepViewController {
    
    @IBOutlet fileprivate weak var btnNumberOfOccupants: UIButton!
    @IBOutlet fileprivate weak var btnMinus: UIButton!
    @IBOutlet fileprivate weak var btnPlus: UIButton!
    
    fileprivate var numberOfOccupants = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        //Set defaults
        AddLocationBuilder.shared.set(occupants: numberOfOccupants)
        
        prefillWithBuilderInfo()
    }
    
    fileprivate func configureUI() {
        btnNumberOfOccupants.styleSquareWithRoundCorners()
        btnMinus.styleSquareWithRoundCorners()
        btnPlus.styleSquareWithRoundCorners()
    }
    
    override func prefillWithBuilderInfo() {
        if let occupants = AddLocationBuilder.shared.occupants {
            numberOfOccupants = occupants
            self.btnNumberOfOccupants.setTitle("\(numberOfOccupants)", for: .normal)
        }
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func increaseOccupants() {
        if numberOfOccupants < LocationInfoHelper.kOccupantsMax {
            numberOfOccupants += 1
            self.btnNumberOfOccupants.setTitle("\(numberOfOccupants)", for: .normal)
            
            AddLocationBuilder.shared.set(occupants: numberOfOccupants)
        }
    }
    
    @IBAction fileprivate func decreaseOccupants() {
        if numberOfOccupants > LocationInfoHelper.kOccupantsMin {
            numberOfOccupants -= 1
            self.btnNumberOfOccupants.setTitle("\(numberOfOccupants)", for: .normal)
            
            AddLocationBuilder.shared.set(occupants: numberOfOccupants)
        }
    }
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationGoalsViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
}
