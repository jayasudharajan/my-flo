//
//  SelectDeviceToPairViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 13/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class SelectDeviceToPairViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var devices: [DeviceToPair] = []
    
    @IBOutlet fileprivate weak var addDeviceToLocationLabel: UILabel!
    @IBOutlet fileprivate weak var locationAddressLabel: UILabel!
    @IBOutlet fileprivate weak var devicesTableView: UITableView!
    @IBOutlet fileprivate weak var devicesTableViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarWithCancel(returningToRoot: true)
        getDeviceTypes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let location = LocationsManager.shared.selectedLocation {
            addDeviceToLocationLabel.text = "add_a_device_to".localized + " " + location.nickname
            locationAddressLabel.text = location.address
        } else {
            addDeviceToLocationLabel.text = ""
            locationAddressLabel.text = ""
        }
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Devices
    fileprivate func getDeviceTypes() {
        showLoadingSpinner("loading".localized)
        
        DevicesHelper.getTypes { (error, devices) in
            self.hideLoadingSpinner()
            
            if let e = error {
                self.showPopup(title: "error_popup_title".localized, description: e.message)
            } else {
                self.devices = devices
                self.devicesTableView.reloadData()
                self.devicesTableViewHeight.constant = CGFloat(devices.count * 105)
                self.devicesTableView.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - UITableView protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceToPairTableViewCell.storyboardId) as? DeviceToPairTableViewCell {
            cell.configure(devices[indexPath.row])
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: DeviceNicknameViewController.storyboardId, sender: indexPath.row)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? DeviceNicknameViewController, let i = sender as? Int {
            viewController.device = devices[i]
        }
    }
    
}
