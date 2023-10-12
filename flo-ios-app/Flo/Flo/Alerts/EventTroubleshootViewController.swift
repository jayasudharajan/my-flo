//
//  EventTroubleshootViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 09/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class EventTroubleshootViewController: EventBaseViewController {
    
    @IBOutlet fileprivate weak var conciergeActionButton: UIButton!
    @IBOutlet fileprivate weak var conciergeShield1View: UIView!
    @IBOutlet fileprivate weak var conciergeShield2View: UIView!
    @IBOutlet fileprivate weak var conciergeHintView: UIView!
    @IBOutlet fileprivate weak var conciergeHintLabel: UILabel!
    
    @IBOutlet fileprivate weak var healthTestButton: UIButton!
    
    @IBAction fileprivate func runHealthTestAction() {
        if let id = event.device?.id, let device = DevicesHelper.getOneLocally(id) {
            if device.healthTestStatus == .running || device.healthTestStatus == .pending {
                goToHealthTestProgress()
            } else {
                checkAndRunHealthTest()
            }
        }
    }
    
    @IBAction fileprivate func viewTipsAction() {
        if let url = event.alert?.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction fileprivate func waterConciergeAction() {
        if let location = event.location {
            if location.floProtect {
                // TODO: - get the real subscription
                ChatHelper.setupAndStart(in: self.navigationController, status: "active_subscriber")
            } else {
                if let url = URL(string: "https://user.meetflo.com/floprotect?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let severity = event.alert?.severity ?? .info
        let alertId = event.alert?.id ?? 0
        let isShutoff = event.alert?.isShutoff ?? false
        
        switch severity {
        case .critical:
            break
        case .warning:
            if alertId > 27 && alertId < 32 && !isShutoff {
                healthTestButton.isHidden = false
            }
        case .info:
            break
        }
        
        setupNavBarWithBack(andTitle: "troubleshoot".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        
        if allowsUserInteraction {
            healthTestButton.layer.cornerRadius = healthTestButton.frame.height / 2
            healthTestButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 90)
        } else {
            healthTestButton.isHidden = true
        }
        
        conciergeActionButton.layer.cornerRadius = conciergeActionButton.frame.height / 2
        conciergeActionButton.layer.shadowRadius = 8
        conciergeActionButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        conciergeActionButton.layer.shadowOpacity = 0.5
        conciergeActionButton.layer.masksToBounds = false
        
        conciergeShield1View.layer.cornerRadius = conciergeShield1View.frame.height / 2
        conciergeShield2View.layer.cornerRadius = conciergeShield2View.frame.height / 2
        
        conciergeHintView.layer.cornerRadius = 20
        conciergeHintView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        conciergeHintView.layer.borderWidth = 1
        conciergeHintView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        conciergeHintView.layer.shadowRadius = 8
        conciergeHintView.layer.shadowOffset = CGSize(width: 0, height: 8)
        conciergeHintView.layer.shadowOpacity = 0.2
        conciergeHintView.layer.masksToBounds = false
        
        conciergeHintLabel.text = "water_concierge_alert_tip".localized(args: [event.displayTitle])
        
        if event.location?.floProtect == true {
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.gradientSecondaryGreen.cgColor
            conciergeActionButton.setTitle("open_chat".localized, for: .normal)
        } else {
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.cyan.cgColor
            conciergeActionButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 0)
            conciergeActionButton.setTitle("activate".localized, for: .normal)
            conciergeShield1View.backgroundColor = StyleHelper.colors.darkCyan
            conciergeShield2View.backgroundColor = StyleHelper.colors.darkCyan
        }
    }
    
    // MARK: - Health test methods
    fileprivate func checkAndRunHealthTest() {
        if event.device?.isInstalled == false {
            showPopup(title: "health_test".localized, description: "device_not_installed".localized)
        } else if let gpm = event.device?.gpm, let psi = event.device?.psi, let valveState = event.device?.valveState {
            if gpm > 0 {
                showPopup(title: "health_test".localized, description: "flow_open".localized)
            } else if psi < 10 && valveState == .open {
                showPopup(title: "health_test".localized, description: "psi_below_10_valve_opened".localized)
            } else if psi < 10 && valveState == .closed {
                showPopup(title: "health_test".localized, description: "psi_below_10_valve_closed".localized)
            } else if psi > 10 && valveState == .closed {
                showPopup(title: "health_test".localized, description: "psi_above_10_valve_closed".localized)
            } else {
                showPopup(
                    title: "run_health_test".localized,
                    description: "health_tests_continue_q".localized,
                    options: [
                        AlertPopupOption(title: "start".localized, type: .normal, action: {
                            self.runHealthTest()
                        }),
                        AlertPopupOption(title: "cancel".localized, type: .cancel, action: nil)
                    ]
                )
            }
        }
    }
    
    fileprivate func runHealthTest() {
        if FloApiRequest.demoModeEnabled() {
            goToHealthTestProgress()
        } else if let device = event.device {
            showLoadingSpinner("loading".localized)
            HealthTestHelper.runHealthTest(device: device, whenFinished: { (error, _) in
                self.hideLoadingSpinner()
                
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    self.goToHealthTestProgress()
                }
            })
        }
    }
    
    fileprivate func goToHealthTestProgress() {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        
        if let device = event.device, let healthTestController = storyboard.instantiateViewController(
            withIdentifier: HealthTestViewController.storyboardId
        ) as? HealthTestViewController {
            healthTestController.device = device
            navigationController?.pushViewController(healthTestController, animated: true)
        }
    }

}
