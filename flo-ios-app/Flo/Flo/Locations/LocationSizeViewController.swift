//
//  LocationSizeViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/13/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationSizeViewController: BaseAddLocationStepViewController {
    
    @IBOutlet fileprivate weak var option1: FloOptionButton!
    @IBOutlet fileprivate weak var option2: FloOptionButton!
    @IBOutlet fileprivate weak var option3: FloOptionButton!
    @IBOutlet fileprivate weak var option4: FloOptionButton!
    @IBOutlet fileprivate weak var option5: FloOptionButton!
    
    fileprivate var validator: SingleChoiceValidator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator = SingleChoiceValidator(objectsToValidate: [option1, option2, option3, option4, option5])
        self.configureView()
        prefillWithBuilderInfo()
    }
    
    fileprivate func configureView() {
        let isImperial = MeasuresHelper.getMeasureSystem() == .imperial
        let unitString = " " + MeasuresHelper.unitName(for: .area)
        
        //UI Customization
        option1.setTitle( String(format: "less_than_number".localized, isImperial ? 700 : 70) + unitString, for: .normal)
        option2.setTitle( String(format: "range".localized,
                                 isImperial ? 700 : 70,
                                 isImperial ? 1000 : 100) + unitString, for: .normal)
        option3.setTitle( String(format: "range".localized,
                                 isImperial ? 1001 : 101,
                                 isImperial ? 2000 : 200) + unitString, for: .normal)
        option4.setTitle( String(format: "range".localized,
                                 isImperial ? 2001 : 201,
                                 isImperial ? 4000 : 400) + unitString, for: .normal)
        option5.setTitle( String(format: "more_than_number".localized,
                                 isImperial ? 4000 : 400) + unitString, for: .normal)
        
        disableNextStep()
    }
    
    override public func prefillWithBuilderInfo() {
        if let size = AddLocationBuilder.shared.locationSize {
            
            let option: FloOptionButton = size == option1.backendIdentifier ? option1
            : size == option2.backendIdentifier ? option2
            : size == option3.backendIdentifier ? option3
            : size == option4.backendIdentifier ? option4 : option5

            didPressOptionButton(option)
        }
    }
    
    // MARK: Actions
    
    @IBAction public func didPressOptionButton(_ button: FloOptionButton) {
        self.validator?.selectOption(button)
        
        guard let size = self.validator?.getSelectedOption()?.backendIdentifier else {
            return
        }
        
        AddLocationBuilder.shared.set(locationSize: size)
        
        enableNextStep()
    }
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationStoriesViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
}
