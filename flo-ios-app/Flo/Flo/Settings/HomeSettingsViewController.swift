//
//  HomeSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 26/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class HomeSettingsViewController: FloBaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet fileprivate weak var lblLocationNickname: UILabel!
    @IBOutlet fileprivate weak var lblLocationAddress: UILabel!
    @IBOutlet fileprivate weak var txtNickname: UITextField!
    @IBOutlet fileprivate weak var lblGoals: UILabel!
    @IBOutlet fileprivate weak var viewFloProtect: UIView!
    @IBOutlet fileprivate weak var lblFloProtect: UILabel!
    @IBOutlet fileprivate weak var devicesTableHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var btnRemoveHome: UIButton!
    
    public var location: LocationModel!
    
    static fileprivate let kDeviceCellHeight: CGFloat = 58

    fileprivate var devices: [DeviceModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarWithBack(andTitle: "home_settings".localized, tint: StyleHelper.colors.white,
                            titleColor: StyleHelper.colors.white)
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        viewFloProtect.layer.shadowColor = StyleHelper.colors.gradientSecondaryGreen.cgColor
        viewFloProtect.layer.shadowRadius = 8
        viewFloProtect.layer.shadowOffset = CGSize(width: 0, height: 6)
        viewFloProtect.layer.masksToBounds = false
        
        btnRemoveHome.backgroundColor = StyleHelper.colors.whiteWithTransparency01
        btnRemoveHome.layer.borderColor = StyleHelper.colors.whiteWithTransparency015.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for location in LocationsManager.shared.locations where location.id == self.location.id {
            self.location = location
            break
        }
        fillWithInformation()
    }
    
    fileprivate func fillWithInformation() {
        
        lblLocationNickname.text = location.nickname
        lblLocationAddress.text = location.address
        txtNickname.text = !location.nickname.isEmpty ? location.nickname : location.address
        
        let dailyGoal = location.gallonsPerDayGoal
        lblGoals.text = String(format: "%.0f \(MeasuresHelper.unitAbbreviation(for: .volume))", MeasuresHelper.adjust(dailyGoal, ofType: .volume).rounded(.toNearestOrAwayFromZero))
        
        viewFloProtect.backgroundColor = location.floProtect ?
            StyleHelper.colors.green : StyleHelper.colors.whiteWithTransparency02
        viewFloProtect.layer.shadowOpacity = location.floProtect ? 0.5 : 0
        lblFloProtect.text = location.floProtect ? "on".localized.uppercased() : "off".localized.uppercased()
        
        devices = location.devices
        devicesTableHeight.constant = HomeSettingsViewController.kDeviceCellHeight + HomeSettingsViewController.kDeviceCellHeight * CGFloat(devices.count) + 10
    }
    
    fileprivate func updateNickname(_ sender: UITextField) {
        if !FloApiRequest.demoModeEnabled() {
            
            guard
                sender == txtNickname,
                let nickname = sender.text
            else {
                return
            }
            
            showLoadingSpinner("please_wait".localized)
            
            FloApiRequest(
                controller: "v2/locations/\(self.location.id)",
                method: .post,
                queryString: nil,
                data: ["nickname": nickname as AnyObject],
                done: { (error, _ ) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    } else {
                        self.lblLocationNickname.text = nickname
                        self.location.setNickname(nickname)
                        sender.resignFirstResponder()
                    }
            }).secureFloRequest()
        } else {
            showFeatureNotSupportedInDemoModeAlert()
        }
    }
    
    func performValidationsOn( _ textField: UITextField) {
        textField.cleanError()
        
        switch textField {
        case txtNickname:
            let nickname = txtNickname.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if nickname.isEmpty {
                txtNickname.displayError("nickname_not_empty".localized)
            } else if !nickname.isShorterThan(257) {
                txtNickname.displayError("nickname_too_long".localized)
            } else if !LocationsManager.shared.locations.filter({ (location) -> Bool in
                return location.nickname.lowercased() == nickname.lowercased() && location.id != self.location.id
            }).isEmpty {
                txtNickname.displayError("you_already_have_a_home_with_that_name".localized)
            } else {
                updateNickname(txtNickname)
            }
        default:
            break
        }
    }
    
    @objc fileprivate func goToMyProfile() {
        performSegue(withIdentifier: "showUserSettings", sender: nil)
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Table view protocol
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let deviceCell = tableView.dequeueReusableCell(withIdentifier: "deviceCell")
            as? ConnectedDeviceTableViewCell else {
            return UITableViewCell()
        }
        
        deviceCell.updateWith(devices[indexPath.row])
        return deviceCell
    }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return HomeSettingsViewController.kDeviceCellHeight
    }
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return HomeSettingsViewController.kDeviceCellHeight
    }
    
    internal func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let deviceFooter = tableView.dequeueReusableCell(withIdentifier: "deviceFooter")
            as? ConnectWithNewDeviceTableViewCell else {
            return UITableViewCell()
        }
        
        return deviceFooter
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let deviceSettingsViewController =
            storyboard.instantiateViewController(withIdentifier: DeviceSettingsViewController.storyboardId)
            as? DeviceSettingsViewController else {
                return
        }
        
        deviceSettingsViewController.device = devices[indexPath.row]
        navigationController?.pushViewController(deviceSettingsViewController, animated: true)
    }
    
    // MARK: - Text field delegate
    override internal func textFieldDidEndEditing(_ textField: UITextField) {
         performValidationsOn(textField)
    }
   
    override public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

     // MARK: - Actions
    
    @IBAction fileprivate func goToFloProtectSettings() {
        let storyboard = UIStoryboard(name: "FloProtect", bundle: nil)
        if let floProtectVC = storyboard.instantiateViewController(withIdentifier: FloProtectViewController.storyboardId) as? FloProtectViewController {
            floProtectVC.location = location
            navigationController?.pushViewController(floProtectVC, animated: true)
        }
    }
    
    @IBAction fileprivate func goToAddNewDevice() {
        connectNewDevice()
    }
    
    @IBAction fileprivate func goToLocationSettings() {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let locationSettingsViewController =
            storyboard.instantiateViewController(withIdentifier: LocationSettingsViewController.storyboardId)
                as? LocationSettingsViewController else {
                    return
        }
        
        locationSettingsViewController.location = self.location
        navigationController?.pushViewController(locationSettingsViewController, animated: true)
    }
    
    @IBAction fileprivate func removeHome() {
        guard !FloApiRequest.demoModeEnabled() else {
            showFeatureNotSupportedInDemoModeAlert()
            return
        }
        
        if location.devices.count == 0 {
            showPopup(title: "remove_home_q".localized, description: "confirm_remove_home".localized, options: [AlertPopupOption(title: "remove_home".localized, type: .normal, action: {
                
                self.showLoadingSpinner("loading".localized)
                FloApiRequest(
                    controller: "v2/locations/\(self.location.id)",
                    method: .delete,
                    queryString: nil,
                    data: nil,
                    done: { (error, _ ) in
                        self.hideLoadingSpinner()
                        if let e = error {
                            self.showPopup(error: e)
                        } else {
                            LocationsManager.shared.updateLocationLocally(id: self.location.id, nil)
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                ).secureFloRequest()
                
            }), AlertPopupOption(title: "cancel".localized, type: .cancel, action: nil)])
        } else {
            showPopup(title: "remove_home".localized, description: "devices_linked_to_this_location".localized, options: [AlertPopupOption(title: "ok".localized, type: .normal, action: nil)])
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGoalSettings" {
            if let destController = segue.destination as? GoalsSettingsViewController {
                destController.location = self.location
            }
        }
    }
}
