//
//  DeviceNicknameViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 14/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import CoreLocation

internal class DeviceNicknameViewController: FloBaseViewController, CLLocationManagerDelegate {
    
    public var device: DeviceToPair!
    fileprivate var locationManager = CLLocationManager()
    
    @IBOutlet fileprivate weak var deviceImageView: UIImageView!
    @IBOutlet fileprivate weak var nicknameLabel: UILabel!
    @IBOutlet fileprivate weak var nicknameTextField: UITextField!
    @IBOutlet fileprivate weak var nextButton: UIButton!
    
    @IBAction fileprivate func nextAction() {
        switch device.model {
        case "flo_device_v2":
            performSegue(withIdentifier: PlugDeviceViewController.storyboardId, sender: nil)
        case "puck":
            break
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithCancel(returningToRoot: true)
        locationManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        manageLocationAccess()
        NotificationCenter.default.addObserver(self, selector: #selector(manageLocationAccess), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        deviceImageView.image = device.image
        nicknameLabel.text = "give_your_device_a_nickname".localized(args: [device.typeFriendly])
        nicknameTextField.placeholder = "my_flo_device".localized
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Location usage and delegate methods
    @objc fileprivate func manageLocationAccess() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showLocationDeniedPopup()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            showLocationDeniedPopup()
        }
    }
    
    fileprivate func showLocationDeniedPopup() {
        showPopup(
            title: "location_access_required_to_continue".localized,
            description: "location_access_required_description".localized,
            options: [
                AlertPopupOption(title: "app_settings".localized, type: .normal, action: {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                }),
                AlertPopupOption(title: "cancel".localized, type: .cancel, action: {
                    self.goToRoot()
                })
            ]
        )
    }
    
    // MARK: - TextField protocol methods
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _ = validateNickname()
    }
    
    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let rangeToReplace = Range(range, in: text) {
            let textToReplace = text[rangeToReplace]
            let finalLength = text.count - textToReplace.count + string.count
            
            return finalLength <= 24
        }
        
        return false
    }
    
    // MARK: - Text fields validation
    fileprivate func validateNickname() -> Bool {
        nicknameTextField.resignFirstResponder()
        nextButton.isEnabled = false
        nextButton.alpha = 0.4
        
        let nickname = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if nickname.isEmpty {
            nicknameTextField.displayError("nickname_not_empty".localized)
            return false
        }
        
        if !nickname.isShorterThan(257) {
            nicknameTextField.displayError("nickname_too_long".localized)
            return false
        }
        
        for device in LocationsManager.shared.selectedLocation?.devices ?? [] where nickname.lowercased() == device.nickname.lowercased() {
            nicknameTextField.displayError("nickname_already_in_use".localized)
            return false
        }
        
        nextButton.isEnabled = true
        nextButton.alpha = 1
        device.nickname = nickname
        
        return true
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return validateNickname()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PlugDeviceViewController {
            viewController.device = device
        }
    }

}
