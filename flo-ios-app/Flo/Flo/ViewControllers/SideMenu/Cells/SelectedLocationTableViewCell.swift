//
//  SelectedLocationTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 06/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SideMenu

internal class SelectedLocationTableViewCell: UITableViewCell {
    
    fileprivate var location: LocationModel?

    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var modeView: UIView!
    @IBOutlet fileprivate weak var modeViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var modeLabel: UILabel!
    @IBOutlet fileprivate weak var occupantsLabel: UILabel!
    @IBOutlet fileprivate weak var nicknameLabel: UILabel!
    @IBOutlet fileprivate weak var addressLabel: UILabel!
    
    @IBOutlet fileprivate weak var floProtectButton: UIButton!
    @IBOutlet fileprivate weak var floProtectLabel: UILabel!
    
    @IBOutlet fileprivate weak var alertContainerView: UIView!
    @IBOutlet fileprivate weak var alertView: UIView!
    @IBOutlet fileprivate weak var alertLabel: UILabel!
    
    @IBAction fileprivate func floProtectAction() {
        SideMenuManager.default.menuLeftNavigationController?.dismiss(animated: true) {
            guard
                let controller = SideMenuManager.default.menuLeftNavigationController?.sideMenuDelegate as? FloBaseViewController,
                let location = self.location
            else { return }
            
            let storyboard = UIStoryboard(name: "FloProtect", bundle: nil)
            if let floProtectVC = storyboard.instantiateViewController(withIdentifier: FloProtectViewController.storyboardId) as? FloProtectViewController {
                floProtectVC.location = location
                controller.navigationController?.pushViewController(floProtectVC, animated: true)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 0)
        containerView.layer.cornerRadius = 10
        
        alertContainerView.layer.cornerRadius = 11
        alertView.layer.cornerRadius = 8
        
        modeView.layer.cornerRadius = 4
        
        floProtectButton.layer.cornerRadius = 24
        floProtectButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        floProtectButton.layer.shadowRadius = 10
        floProtectButton.layer.shadowOpacity = 0.3
    }

    public func configure(_ location: LocationModel) {
        self.location = location
        
        if location.devices.isEmpty {
            modeLabel.text = ""
            modeViewHeight.constant = 0
            modeView.isHidden = true
        } else {
            modeViewHeight.constant = 18
            modeView.isHidden = false
            var learningDevices = 0
            for device in location.devices {
                let isLearning = device.isConnected && device.isInstalled && device.healthTestStatus != .running && device.healthTestStatus != .pending && device.systemModeLocked
                learningDevices += isLearning ? 1 : 0
            }
            if learningDevices == location.devices.count {
                modeLabel.text = "learning".localized
            } else {
                modeLabel.text = location.systemMode.rawValue.localized
            }
        }
        
        occupantsLabel.text = "1" //Should show the numbers of users that can control the device
        nicknameLabel.text = location.nickname
        addressLabel.text = location.address
        
        if location.floProtect {
            floProtectButton.backgroundColor = StyleHelper.colors.green
            floProtectButton.layer.shadowColor = StyleHelper.colors.green.cgColor
            floProtectLabel.text = "floprotect_enabled".localized
        } else {
            floProtectButton.backgroundColor = StyleHelper.colors.cyan
            floProtectButton.layer.shadowColor = StyleHelper.colors.cyan.cgColor
            floProtectLabel.text = "activate_floprotect".localized
        }
        
        var criticalAlerts = 0
        var warningAlerts = 0
        for device in location.devices {
            criticalAlerts += device.criticalAlerts
            warningAlerts += device.warningAlerts
        }
        
        if criticalAlerts + warningAlerts > 0 {
            alertContainerView.isHidden = false
            
            if criticalAlerts > 0 {
                alertLabel.text = "\(criticalAlerts)"
                alertView.backgroundColor = StyleHelper.colors.red
            } else {
                alertLabel.text = "\(warningAlerts)"
                alertView.backgroundColor = StyleHelper.colors.orange
            }
        } else {
            alertContainerView.isHidden = true
        }
    }

}
