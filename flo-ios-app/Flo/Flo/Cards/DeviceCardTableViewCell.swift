//
//  DeviceCardTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SideMenu

internal class DeviceCardTableViewCell: UITableViewCell {
    
    fileprivate var device: DeviceModel!
    fileprivate var statusWrapper = StatusWrapper.unknown
    fileprivate var criticalAlertsAmount = 0
    fileprivate var warningAlertsAmount = 0
    fileprivate var singleDevice = true
    
    @IBOutlet fileprivate weak var deviceImageView: UIImageView!
    @IBOutlet fileprivate weak var deviceNameLabel: UILabel!
    @IBOutlet fileprivate weak var deviceStatusLabel: UILabel!
    @IBOutlet fileprivate weak var wifiImageView: UIImageView!
    @IBOutlet fileprivate weak var wifiImageRightMargin: NSLayoutConstraint!
    @IBOutlet fileprivate weak var alertsView: UIView!
    @IBOutlet fileprivate weak var alertsLabel: UILabel!
    @IBOutlet fileprivate weak var deviceStatusImageView: UIImageView!
    @IBOutlet fileprivate weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        alertsView.layer.cornerRadius = 10
        arrowImageView.image = arrowImageView.image?.withRenderingMode(.alwaysTemplate)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func configure(_ device: DeviceModel, asSingle: Bool) {
        self.device = device
        singleDevice = asSingle
        let amountChanged = criticalAlertsAmount != device.criticalAlerts || warningAlertsAmount != device.warningAlerts
        
        if !device.isConnected {
            configure(as: .notConnected)
        } else if device.healthTestStatus == .running || device.healthTestStatus == .pending {
            configure(as: .runningTest, forceUpdate: amountChanged)
        } else if device.valveState == .closed {
            configure(as: .valveClosed, forceUpdate: amountChanged)
        } else if !device.isInstalled {
            configure(as: .notInstalled)
        } else if device.systemModeLocked {
            configure(as: .learning)
        } else if device.criticalAlerts + device.warningAlerts > 0 {
            configure(as: .hasAlerts, forceUpdate: amountChanged)
            criticalAlertsAmount = device.criticalAlerts
            warningAlertsAmount = device.warningAlerts
        } else {
            configure(as: .secure)
        }
        
        deviceNameLabel.text = device.nickname
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdate(_:)), name: device.statusUpdateNotificationName, object: nil)
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress {
            device.setStatus(status)
            
            if !status.isConnected {
                configure(as: .notConnected)
            } else if status.healthTestStatus == .running || status.healthTestStatus == .pending {
                configure(as: .runningTest)
            } else if status.valveState == .closed {
                configure(as: .valveClosed)
            } else if !device.isInstalled {
                configure(as: .notInstalled)
            } else if device.systemModeLocked {
                configure(as: .learning)
            } else if device.criticalAlerts + device.warningAlerts > 0 {
                configure(as: .hasAlerts)
            } else {
                configure(as: .secure)
            }
        }
    }
    
    // MARK: - Status configuration
    fileprivate func configure(as status: StatusWrapper, forceUpdate: Bool = false) {
        configureConnection()
        
        if statusWrapper == status && !forceUpdate { return }
        statusWrapper = status
        
        wifiImageRightMargin.constant = 44
        
        switch status {
        case .notConnected:
            deviceStatusLabel.text = "offline".localized
            deviceStatusLabel.textColor = StyleHelper.colors.red
            deviceStatusImageView.isHidden = false
            deviceStatusImageView.image = UIImage(named: "red-triangle-alert-icon")
            alertsView.isHidden = true
        case .runningTest:
            deviceStatusLabel.text = "health_test_running".localized
            deviceStatusLabel.textColor = StyleHelper.colors.red
            configureAlerts()
        case .valveClosed:
            deviceStatusLabel.text = "valve_closed".localized
            deviceStatusLabel.textColor = StyleHelper.colors.red
            configureAlerts()
        case .notInstalled:
            deviceStatusLabel.text = "needs_install".localized
            deviceStatusLabel.textColor = StyleHelper.colors.red
            deviceStatusImageView.isHidden = false
            deviceStatusImageView.image = UIImage(named: "red-triangle-alert-icon")
            alertsView.isHidden = true
        case .learning:
            deviceStatusLabel.text = "learning".localized
            deviceStatusLabel.textColor = StyleHelper.colors.darkBlue
            deviceStatusImageView.isHidden = false
            deviceStatusImageView.image = UIImage(named: "blue-info-icon")
            alertsView.isHidden = true
        default:
            deviceStatusLabel.text = ""
            configureAlerts()
        }
    }
    
    // MARK: - Alerts management
    fileprivate func configureAlerts() {
        if device.criticalAlerts > 0 {
            deviceStatusImageView.isHidden = true
            alertsView.isHidden = false
            alertsView.backgroundColor = UIColor(hex: "D75839")
            alertsLabel.text = "\(device.criticalAlerts)"
        } else if device.warningAlerts > 0 {
            deviceStatusImageView.isHidden = true
            alertsView.isHidden = false
            alertsView.backgroundColor = UIColor(hex: "EB9A3A")
            alertsLabel.text = "\(device.warningAlerts)"
        } else {
            wifiImageRightMargin.constant = singleDevice ? 12 : 44
            deviceStatusImageView.isHidden = singleDevice
            deviceStatusImageView.image = UIImage(named: "cyan-check-icon")
            alertsView.isHidden = true
        }
    }
    
    // MARK: - Connection status management
    fileprivate func configureConnection() {
        var deviceImageName = "flo_device_125_v2"
        if device.valveState != .open && device.valveState != .inTransition {
            deviceImageName += "-closed"
        }
        deviceImageView.image = UIImage(named: deviceImageName)
        deviceImageView.alpha = device.isConnected ? 1 : 0.5
        let signalLevel = device.isConnected ? WifiHelper.signalLevel(device.wiFiSignal) : 0
        wifiImageView.image = UIImage(named: "wifi-level\(signalLevel)-icon")?.withRenderingMode(.alwaysTemplate)
    }
    
}
