//
//  AlertsSummaryCardViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/7/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal enum StatusWrapper {
    case notConnected, runningTest, valveClosed, notInstalled, learning, hasAlerts, secure, unknown
}

internal class AlertsSummaryCardViewController: CardViewController {
    
    override var height: CGFloat {
        return 92
    }
    fileprivate var location: LocationModel?
    fileprivate var device: DeviceModel?
    fileprivate var statusWrapper = StatusWrapper.unknown
    fileprivate var criticalAlertsAmount = 0
    fileprivate var warningAlertsAmount = 0
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var alertsStatusImageView: UIImageView!
    @IBOutlet fileprivate weak var alertsTitleLabel: UILabel!
    @IBOutlet fileprivate weak var alertsDescriptionLabel: UILabel!
    @IBOutlet fileprivate weak var actionImageView: UIImageView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 10
    }
    
    // MARK: - Overrides
    override func updateWith(locationInfo: LocationModel) {
        location = locationInfo
        
        var newCriticalAlertsAmount = 0
        var newWarningAlertsAmount = 0
        for device in locationInfo.devices {
            newCriticalAlertsAmount += device.criticalAlerts
            newWarningAlertsAmount += device.warningAlerts
        }
        
        if newCriticalAlertsAmount + newWarningAlertsAmount > 0 {
            let amountChanged = criticalAlertsAmount != newCriticalAlertsAmount || warningAlertsAmount != newWarningAlertsAmount
            configure(as: .hasAlerts, forceUpdate: amountChanged)
            criticalAlertsAmount = newCriticalAlertsAmount
            warningAlertsAmount = newWarningAlertsAmount
        } else {
            configure(as: .secure)
        }
    }
    
    override func updateWith(deviceInfo: DeviceModel) {
        device = deviceInfo
        
        if !deviceInfo.isConnected {
            configure(as: .notConnected)
        } else if !deviceInfo.isInstalled {
            configure(as: .notInstalled)
        } else if deviceInfo.systemModeLocked {
            configure(as: .learning)
        } else if deviceInfo.criticalAlerts + deviceInfo.warningAlerts > 0 {
            let amountChanged = criticalAlertsAmount != deviceInfo.criticalAlerts || warningAlertsAmount != deviceInfo.warningAlerts
            configure(as: .hasAlerts, forceUpdate: amountChanged)
            criticalAlertsAmount = deviceInfo.criticalAlerts
            warningAlertsAmount = deviceInfo.warningAlerts
        } else {
            configure(as: .secure)
        }
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdate(_:)), name: deviceInfo.statusUpdateNotificationName, object: nil)
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), let device = device, status.macAddress == device.macAddress {
            device.setStatus(status)
            
            if !status.isConnected {
                configure(as: .notConnected)
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
        if statusWrapper == status && !forceUpdate { return }
        statusWrapper = status
        
        if let gesture = containerView.gestureRecognizers?.first {
            containerView.removeGestureRecognizer(gesture)
        }
        
        for layer in containerView.layer.sublayers ?? [] {
            if let gradientLayer = layer as? FloGradientLayer {
                gradientLayer.removeFromSuperlayer()
            }
        }
        
        switch status {
        case .notConnected:
            containerView.backgroundColor = StyleHelper.colors.transparency20
            alertsStatusImageView.image = UIImage(named: "red-triangle-alert-icon")
            alertsTitleLabel.text = "device_offline".localized
            alertsDescriptionLabel.text = "bring_device_back_online".localized
            actionImageView.isHidden = false
            containerView.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(goToWeb)
            ))
        case .notInstalled:
            containerView.backgroundColor = StyleHelper.colors.transparency20
            alertsStatusImageView.image = UIImage(named: "red-triangle-alert-icon")
            alertsTitleLabel.text = "needs_install".localized
            alertsDescriptionLabel.text = "install_device_on_main_water_line".localized
            actionImageView.isHidden = false
            containerView.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(goToWeb)
            ))
        case .learning:
            containerView.backgroundColor = StyleHelper.colors.transparency20
            alertsStatusImageView.image = UIImage(named: "blue-info-icon")
            alertsTitleLabel.text = "learning_mode".localized
            alertsDescriptionLabel.text = "learning_homes_water_habits".localized
            actionImageView.isHidden = false
            containerView.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(goToWeb)
            ))
        case .hasAlerts:
            var criticalAlerts = device?.criticalAlerts ?? 0
            var warningAlerts = device?.warningAlerts ?? 0
            if let location = location {
                criticalAlerts = 0
                warningAlerts = 0
                for device in location.devices {
                    criticalAlerts += device.criticalAlerts
                    warningAlerts += device.warningAlerts
                }
            }
            
            if criticalAlerts > 0 {
                containerView.backgroundColor = StyleHelper.colors.red
                alertsStatusImageView.image = UIImage(named: "red-round-alert-icon")
                alertsTitleLabel.text = "\(criticalAlerts) " + (criticalAlerts == 1 ? "critical_alert".localized : "critical_alerts".localized)
            } else {
                containerView.layer.addGradient(from: StyleHelper.colors.orange, to: StyleHelper.colors.darkOrange, angle: 270)
                alertsStatusImageView.image = UIImage(named: "orange-round-alert-icon")
                alertsTitleLabel.text = "\(warningAlerts) " + (warningAlerts == 1 ? "warning_alert".localized : "warning_alerts".localized)
            }
            alertsDescriptionLabel.text = "view_alerts".localized
            actionImageView.isHidden = false
            containerView.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(goToAlerts)
            ))
        default:
            containerView.backgroundColor = StyleHelper.colors.transparency20
            alertsStatusImageView.image = UIImage(named: "cyan-check-icon")
            alertsTitleLabel.text = "youre_secure_".localized
            alertsDescriptionLabel.text = "no_alerts".localized
            actionImageView.isHidden = true
        }
    }
    
    // MARK: - Navigation
    @objc fileprivate func goToWeb() {
        var urlString = ""
        
        switch statusWrapper {
        case .notConnected:
            urlString = "https://support.meetflo.com/hc/en-us/articles/115000748594-Device-Offline"
        case .notInstalled:
            urlString = "https://support.meetflo.com/hc/en-us/articles/115003205573--Needs-Install-alert-on-Dashboard"
        case .learning:
            urlString = "https://support.meetflo.com/hc/en-us/articles/115003205673-Learning-Mode"
        default:
            return
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc fileprivate func goToAlerts() {
        if let deviceId = device?.id {
            if let alertsViewController = UIStoryboard(name: "Alerts", bundle: nil).instantiateViewController(withIdentifier: AlertsViewController.storyboardId) as? AlertsViewController {
                alertsViewController.deviceIds = [deviceId]
                alertsViewController.isDeviceFilterEnabled = false
                navigationController?.pushViewController(alertsViewController, animated: true)
            }
        } else {
            guard
                let tabBarController = navigationController?.parent as? UITabBarController,
                let viewControllers = tabBarController.viewControllers,
                viewControllers.count > 1,
                let alertsNavController = viewControllers[1] as? UINavigationController,
                let alertsViewController = alertsNavController.viewControllers.first as? AlertsViewController
            else { return }
            
            var deviceIds: [String] = []
            for device in location?.devices ?? [] {
                deviceIds.append(device.id)
            }
            alertsViewController.deviceIds = deviceIds
            
            tabBarController.selectedIndex = 1
        }
    }
    
}
