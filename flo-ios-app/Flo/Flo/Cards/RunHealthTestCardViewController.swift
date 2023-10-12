//
//  RunHealthTestCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 27/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class RunHealthTestCardViewController: CardViewController {

    override var height: CGFloat {
        return 144
    }
    
    fileprivate var device: DeviceModel!
    
    @IBOutlet fileprivate weak var runHealthTestButton: UIButton!
    @IBOutlet fileprivate weak var hintView: UIView!
    @IBOutlet fileprivate weak var lblRunHealthTest: UILabel!
    
    fileprivate var isRunningHealthTest: Bool {
        return self.device.healthTestStatus == .running || self.device.healthTestStatus == .pending
    }
    
    static func getInstance(withHeight height: CGFloat? = nil, device: DeviceModel) -> CardViewController {
        if let instance = super.getInstance(withHeight: height) as? RunHealthTestCardViewController {
            instance.device = device
            return instance
        }
        return super.getInstance()
    }
    
    @IBAction fileprivate func infoAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        hintView.isHidden = false
        let finishesHidden = !sender.isSelected
        finishesHidden ? (hintView.alpha = 1) : (hintView.alpha = 0)
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                finishesHidden ? (self.hintView.alpha = 0) : (self.hintView.alpha = 1)
            },
            completion: { complete in
                if complete {
                    self.hintView.isHidden = finishesHidden
                }
            }
        )
    }
    
    @IBAction fileprivate func runHealthTestAction() {
        if isRunningHealthTest {
            showHealthTestProgress()
        } else if canRunHealthTest() {
            showPopup(
                title: "run_health_test".localized,
                description: "health_tests_continue_q".localized,
                options: [
                    AlertPopupOption(title: "start".localized(), type: .normal, action: {
                        self.showLoadingSpinner("loading".localized)
                        self.runHealthTest()
                    }),
                    AlertPopupOption(title: "cancel".localized, type: .cancel, action: nil)
                ]
            )
        }
    }

    fileprivate func canRunHealthTest () -> Bool {
        
        // Device not installed
        if !self.device.isInstalled {
            self.showPopup(title: "health_test".localized, description: "device_not_installed".localized,
                           options: [AlertPopupOption(title: "ok".localized)])
            return false
        }
        
        if let gpm = device.gpm, let psi = device.psi {
            // Flow >0gpm
            if gpm > 0 {
                self.showPopup(title: "health_test".localized, description: "flow_open".localized,
                               options: [AlertPopupOption(title: "ok".localized)])
                return false
            }
            
            // Pressure is <10psi and valve is opened
            if psi < 10 && device.valveState == .open {
                self.showPopup(title: "health_test".localized, description: "psi_below_10_valve_opened".localized,
                               options: [AlertPopupOption(title: "ok".localized)])
                return false
            }
            
            // Pressure is <10psi and valve is closed
            if psi < 10 && device.valveState == .closed {
                self.showPopup(title: "health_test".localized, description: "psi_below_10_valve_closed".localized,
                               options: [AlertPopupOption(title: "ok".localized)])
                return false
            }
            
            // Pressure is >10psi but valve is closed
            if psi > 10 && device.valveState == .closed {
                self.showPopup(title: "health_test".localized, description: "psi_above_10_valve_closed".localized,
                               options: [AlertPopupOption(title: "ok".localized)])
                return false
            }
            
            return true
        }
        
        return false
    }
    
    fileprivate func runHealthTest() {
        
        guard !FloApiRequest.demoModeEnabled() else {
            self.hideLoadingSpinner()
            self.showHealthTestProgress()
            return
        }
        
        HealthTestHelper.runHealthTest(device: device, whenFinished: {(error, _) in
            self.hideLoadingSpinner()
            
            if let e = error {
                self.showPopup(error: e)
            } else {
                self.showHealthTestProgress()
            }
        })
    }
    
    fileprivate func showHealthTestProgress() {
        guard let healthTestController = UIStoryboard(name: "Device", bundle: nil).instantiateViewController(withIdentifier:
            HealthTestViewController.storyboardId) as? HealthTestViewController else {
                return
        }
        
        healthTestController.device = self.device
        self.navigationController?.pushViewController(healthTestController, animated: true)
    }
    
    fileprivate func configureUI(testRunning: Bool) {
        runHealthTestButton.setTitle(testRunning ? "view_progress".localized : "run_manual_health_test".localized,
                                     for: .normal)
        lblRunHealthTest.text = testRunning ? "running_health_test".localized : "check_your_plumbing_for_leaks".localized
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runHealthTestButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Overrides
    override func updateWith(deviceInfo: DeviceModel) {
        device = deviceInfo
        
        configureUI(testRunning: isRunningHealthTest)
        
        runHealthTestButton.isEnabled = deviceInfo.isConnected
        runHealthTestButton.alpha = deviceInfo.isConnected ? 1 : 0.4
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onUpdate(_:)),
            name: device.statusUpdateNotificationName,
            object: nil
        )
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress {
            device.setStatus(status)
            
            runHealthTestButton.isEnabled = status.isConnected
            runHealthTestButton.alpha = status.isConnected ? 1 : 0.4
            
            configureUI(testRunning: isRunningHealthTest)
        }
    }
}
