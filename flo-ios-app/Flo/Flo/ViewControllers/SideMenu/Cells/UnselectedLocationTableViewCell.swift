//
//  UnselectedLocationTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 07/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class UnselectedLocationTableViewCell: UITableViewCell {

    fileprivate var location: LocationModel?
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var modeView: UIView!
    @IBOutlet fileprivate weak var modeViewLeftSpace: NSLayoutConstraint!
    @IBOutlet fileprivate weak var modeLabel: UILabel!
    @IBOutlet fileprivate weak var floProtectView: UIView!
    @IBOutlet fileprivate weak var floProtectLabel: UILabel!
    @IBOutlet fileprivate weak var nicknameLabel: UILabel!
    @IBOutlet fileprivate weak var addressLabel: UILabel!
    
    @IBOutlet fileprivate weak var alertContainerView: UIView!
    @IBOutlet fileprivate weak var alertView: UIView!
    @IBOutlet fileprivate weak var alertLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 10
        
        alertContainerView.layer.cornerRadius = 11
        alertView.layer.cornerRadius = 8
        
        modeView.layer.cornerRadius = 4
        
        floProtectView.layer.cornerRadius = 4
    }

    public func configure(_ location: LocationModel) {
        self.location = location
        
        if location.devices.isEmpty {
            modeLabel.text = ""
            modeViewLeftSpace.constant = -4
            modeView.isHidden = true
        } else {
            modeViewLeftSpace.constant = 20
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
        
        if location.floProtect {
            floProtectView.backgroundColor = StyleHelper.colors.green
            floProtectLabel.text = "on".localized
        } else {
            floProtectView.backgroundColor = StyleHelper.colors.gray
            floProtectLabel.text = "off".localized
        }
        
        nicknameLabel.text = location.nickname
        addressLabel.text = location.address
        
        var criticalAlerts = 0
        var warningAlerts = 0
        for device in location.devices {
            criticalAlerts += device.criticalAlerts
            warningAlerts += device.warningAlerts
        }
        
        if criticalAlerts + warningAlerts > 0 {
            alertContainerView.isHidden = false
            containerView.layer.borderWidth = 1
            
            if criticalAlerts > 0 {
                alertLabel.text = "\(criticalAlerts)"
                alertView.backgroundColor = StyleHelper.colors.red
                containerView.layer.borderColor = StyleHelper.colors.red.cgColor
            } else {
                alertLabel.text = "\(warningAlerts)"
                alertView.backgroundColor = StyleHelper.colors.orange
                containerView.layer.borderColor = StyleHelper.colors.orange.cgColor
            }
        } else {
            alertContainerView.isHidden = true
            containerView.layer.borderColor = nil
            containerView.layer.borderWidth = 0
        }
    }

}
