//
//  LocationDevicesCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SideMenu

internal class LocationDevicesCardViewController: CollapsableCardViewController, UITableViewDelegate, UITableViewDataSource {
    
    override var height: CGFloat {
        if devices.isEmpty {
            return kNoDevicesRowHeight
        }
        return isCollapsed ? kCollapsedHeight : devicesTableView.frame.origin.y + devicesTableHeight.constant + 20
    }
    
    fileprivate var devices: [DeviceModel] = []
    fileprivate let kNoDevicesRowHeight: CGFloat = 112
    fileprivate let kDeviceRowHeight: CGFloat = 70
    fileprivate let kAddDeviceRowHeight: CGFloat = 36
    
    @IBOutlet fileprivate weak var collpaseButton: UIButton!
    @IBOutlet fileprivate weak var addDeviceButton: UIButton!
    @IBOutlet fileprivate weak var addDeviceView: UIView!
    @IBOutlet fileprivate weak var devicesTableView: UITableView!
    @IBOutlet fileprivate weak var devicesTableHeight: NSLayoutConstraint!
    
    @IBAction fileprivate func addDeviceAction() {
        connectNewDevice()
    }
    
    override func updateWith(locationInfo: LocationModel) {
        devices = locationInfo.devices
        collpaseButton.isHidden = devices.isEmpty
        titleLabel.isHidden = devices.isEmpty
        containerView.backgroundColor = devices.isEmpty ? StyleHelper.colors.transparency20 : .white
        addDeviceButton.isEnabled = devices.isEmpty
        addDeviceView.isHidden = !devices.isEmpty
        
        devicesTableView.isHidden = devices.isEmpty
        devicesTableHeight.constant = CGFloat(devices.count) * kDeviceRowHeight + kAddDeviceRowHeight
        if !devices.isEmpty {
            devicesTableView.reloadData()
        }
        
        delegate?.cardHasResized(self)
    }
    
    // MARK: - Table view protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < devices.count {
            if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceCardTableViewCell.storyboardId, for: indexPath) as? DeviceCardTableViewCell {
                cell.configure(devices[indexPath.row], asSingle: devices.count == 1)
                
                return cell
            }
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "AddDeviceCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row < devices.count ? kDeviceRowHeight : kAddDeviceRowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < devices.count {
            if let deviceDetailVC = UIStoryboard(name: "Device", bundle: nil).instantiateViewController(withIdentifier: DeviceDetailViewController.storyboardId) as? DeviceDetailViewController {
                deviceDetailVC.device = devices[indexPath.row]
                navigationController?.pushViewController(deviceDetailVC, animated: true)
            }
        } else {
            if FloApiRequest.demoModeEnabled() {
                showPopup(title: "flo_error".localized + " 002", description: "feature_not_supported_in_demo_mode".localized)
            } else if let viewController = SideMenuManager.default.menuLeftNavigationController?.sideMenuDelegate as? UIViewController {
                viewController.connectNewDevice()
            }
        }
    }
}
