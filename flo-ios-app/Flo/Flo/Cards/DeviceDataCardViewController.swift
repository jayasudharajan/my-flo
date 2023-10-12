//
//  DeviceDataCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 26/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeviceDataCardViewController: CardViewController {
    
    public static let kNotificationChangeValveState = NSNotification.Name(rawValue: "__kChangeValveState")
    
    override var height: CGFloat {
        return 114
    }
    fileprivate var device: DeviceModel!
    
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var locationNameLabel: UILabel!
    @IBOutlet fileprivate weak var wiFiImageView: UIImageView!
    @IBOutlet fileprivate weak var modeView: UIView!
    @IBOutlet fileprivate weak var modeLabel: UILabel!
    @IBOutlet fileprivate weak var deviceImageView: UIImageView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Overrides
    override func updateWith(deviceInfo: DeviceModel) {
        device = deviceInfo
        
        nameLabel.text = device.nickname
        locationNameLabel.text = LocationsManager.shared.selectedLocation?.nickname
        
        var deviceImageName = device.type
        if device.valveState != .open && device.valveState != .inTransition {
            deviceImageName += "-closed"
        }
        
        if UIImage(named: deviceImageName) == nil {
            deviceImageName = "flo_device_125_v2"
            if device.valveState != .open && device.valveState != .inTransition {
                deviceImageName += "-closed"
            }
        }
        
        deviceImageView.image = UIImage(named: deviceImageName)
        
        if !device.isConnected {
            configure(as: .notConnected)
        } else if device.systemModeLocked {
            configure(as: .learning)
        } else {
            configure(as: .secure)
        }
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdate(_:)), name: device.statusUpdateNotificationName, object: nil)
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress {
            device.setStatus(status)
            
            var deviceImageName = device.type
            if status.valveState != .open && status.valveState != .inTransition {
                deviceImageName += "-closed"
            }
            
            if UIImage(named: deviceImageName) == nil {
                deviceImageName = "flo_device_125_v2"
                if status.valveState != .open && status.valveState != .inTransition {
                    deviceImageName += "-closed"
                }
            }
            
            deviceImageView.image = UIImage(named: deviceImageName)
            
            if !status.isConnected {
                configure(as: .notConnected)
            } else if device.systemModeLocked {
                configure(as: .learning)
            } else {
                configure(as: .secure)
            }
        }
    }
    
    // MARK: - Status configuration
    fileprivate func configure(as status: StatusWrapper) {
        let signalLevel = WifiHelper.signalLevel(device.wiFiSignal)
        
        switch status {
        case .notConnected:
            wiFiImageView.image = UIImage(named: "wifi-level0-icon")
            modeView.alpha = 0
            modeLabel.text = "".localized
            deviceImageView.alpha = 0.4
        case .learning:
            wiFiImageView.image = UIImage(named: "wifi-level\(signalLevel)-icon")
            modeView.alpha = 0
            modeLabel.text = "".localized
            deviceImageView.alpha = 1
        default:
            wiFiImageView.image = UIImage(named: "wifi-level\(signalLevel)-icon")
            modeView.alpha = 1
            modeLabel.text = device.systemMode.rawValue.localized
            deviceImageView.alpha = 1
        }
    }
    
    // MARK: Actions
    @IBAction fileprivate func deviceIconTapped() {
        if deviceImageView.alpha == 1 {
            NotificationCenter.default.post(name: DeviceDataCardViewController.kNotificationChangeValveState, object: nil)
        }
    }
    
}
