//
//  LocationStoriesViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/13/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import EasyTipView

internal class LocationStoriesViewController: BaseAddLocationStepViewController {
    
    @IBOutlet fileprivate weak var floors1: FloOptionButton!
    @IBOutlet fileprivate weak var floors2: FloOptionButton!
    @IBOutlet fileprivate weak var floors3: FloOptionButton!
    @IBOutlet fileprivate weak var floors4Plus: FloOptionButton!
    //Values goes from 1 to 10, but should be divided by 2 so we can have .5 bathrooms
    @IBOutlet fileprivate weak var bathrooms: UISlider!
    
    fileprivate var validator: SingleChoiceValidator?
    fileprivate var bathroomTooltip: EasyTipView?
    fileprivate var bathroomTooltipPreferences: EasyTipView.Preferences?
    
    fileprivate var sliderDidChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator = SingleChoiceValidator(objectsToValidate: [floors1, floors2, floors3, floors4Plus])
        
        floors1.tag = 1
        floors2.tag = 2
        floors3.tag = 3
        floors4Plus.tag = 4
        
        self.bathroomTooltipPreferences = EasyTipView.Preferences()
        self.bathroomTooltipPreferences?.drawing.foregroundColor = StyleHelper.colors.white
        self.bathroomTooltipPreferences?.drawing.backgroundColor = StyleHelper.colors.blue
        self.bathroomTooltipPreferences?.animating.dismissDuration = 0.001
        self.bathroomTooltipPreferences?.animating.dismissOnTap = false
        self.bathroomTooltipPreferences?.drawing.arrowPosition = .bottom
        
        prefillWithBuilderInfo()
        
        refreshNextButton()
    }
    
    override func prefillWithBuilderInfo() {
        
        if let storiesTag = AddLocationBuilder.shared.stories {
            if let view = self.view.viewWithTag(storiesTag) as? FloOptionButton {
                self.validator?.selectOption(view)
            }
        }
        
        if let toilets = AddLocationBuilder.shared.toiletCount {
            self.bathrooms.value = toilets * 2
            self.sliderDidChange = true
            //Delay this a bit so screen is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showTooltipInSlider()
            }
        }
    }
    
    @IBAction fileprivate func showTooltipInSlider() {
        for v in bathrooms.subviews {
            if let target = v as? UIImageView, target.subviews.count > 0 {
                let sensitivity = bathrooms.value.rounded()
                self.bathroomTooltip?.dismiss()
                self.bathroomTooltip = EasyTipView(text: (sensitivity / 2).clean, preferences: bathroomTooltipPreferences!)
                self.bathroomTooltip?.show(animated: false, forView: target, withinSuperview: bathrooms)
            }
        }
    }
    
    fileprivate func refreshNextButton() {
        self.configureNextButton(isEnabled: validator?.getSelectedOption() != nil && sliderDidChange)
    }
    
    // MARK: Actions
    
    @IBAction public func didPressOptionButton(_ button: FloOptionButton) {
        self.validator?.selectOption(button)
        
        guard let stories = self.validator?.getSelectedOption()?.tag else {
            return
        }
        
        AddLocationBuilder.shared.set(stories: stories)
        
        refreshNextButton()
    }
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationPlumbingViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
    
    @IBAction func sliderReleased() {
        let sensitivity = bathrooms.value.rounded()
        bathrooms.setValue(sensitivity, animated: true)
        showTooltipInSlider()
        sliderDidChange = true
        AddLocationBuilder.shared.set(toiletCount: bathrooms.value / 2)
        refreshNextButton()
    }
}
