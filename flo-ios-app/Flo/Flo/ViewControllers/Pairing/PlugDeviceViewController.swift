//
//  PlugDeviceViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 14/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class PlugDeviceViewController: FloBaseViewController {
    
    public var device: DeviceToPair!

    @IBOutlet fileprivate weak var pairTitleLabel: UILabel!
    @IBOutlet fileprivate weak var step1Button: UIButton!
    @IBOutlet fileprivate weak var step2Button: UIButton!
    @IBOutlet fileprivate weak var step3Button: UIButton!
    @IBOutlet fileprivate weak var nextButton: UIButton!
    
    @IBAction fileprivate func stepCheckingAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        _ = validateSteps()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithCancel(returningToRoot: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pairTitleLabel.text = "pair".localized + " " + device.nickname
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - View validation
    fileprivate func validateSteps() -> Bool {
        if step1Button.isSelected && step2Button.isSelected && step3Button.isSelected {
            nextButton.isEnabled = true
            nextButton.alpha = 1
            
            return true
        }
        
        nextButton.isEnabled = false
        nextButton.alpha = 0.4
        
        return false
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return validateSteps()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PushToConnectViewController {
            viewController.device = device
        }
    }

}
