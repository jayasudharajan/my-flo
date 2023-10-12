//
//  ValveCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 27/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class ValveCardViewController: CardViewController {
    
    override var height: CGFloat {
        return 144
    }
    fileprivate var device: DeviceModel!
    fileprivate var lastValveState: ValveState = .inTransition
    public weak var delegate: HealthTestDelegate?
    
    @IBOutlet fileprivate weak var valveButton: UIButton!
    @IBOutlet fileprivate weak var waterFlowOnImageView: UIImageView!
    @IBOutlet fileprivate weak var waterFlowOffImageView: UIImageView!
    @IBOutlet fileprivate weak var valveKnotOnImageView: UIImageView!
    @IBOutlet fileprivate weak var valveKnotOffImageView: UIImageView!
    @IBOutlet fileprivate weak var valveStatusLabel: UILabel!
    
    @IBAction fileprivate func valveAction() {
        if !valveButton.isEnabled {
            return
        }
        
        if device.healthTestStatus == .running {
            delegate?.cancelHealthTest()
            return
        }
        
        if device.healthTestStatus == .pending {
            return
        }
        
        let newState: ValveState = lastValveState == .open ? .closed : .open
        let alertTitle = (newState == .open ? "turn_on_water" : "turn_off_water").localized
        let alertMessage = (newState == .open ? "please_confirm_you_want_your_flo_device_to_turn_on_your_water" : "please_confirm_you_want_your_flo_device_to_turn_off_your_water").localized
        let alertOptions = [
            AlertPopupOption(title: "confirm".localized(), type: .normal, action: {
                self.valveButton.isEnabled = false
                
                DevicesHelper.setValveState(newState, for: self.device.id) { (_, result) in
                    if !result {
                        self.configureView()
                    }
                }
            }),
            AlertPopupOption(title: "cancel".localized(), type: .cancel, action: nil)
        ]
        self.showPopup(title: alertTitle, description: alertMessage, options: alertOptions)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopAnimations()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Overrides
    override func updateWith(deviceInfo: DeviceModel) {
        device = deviceInfo
        view.alpha = deviceInfo.isConnected ? 1 : 0.4
        valveButton.isEnabled = deviceInfo.isConnected && deviceInfo.valveState != .inTransition
        
        registerToNotificationsForCurrentDevice()
        startAnimations()
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress {
            device.setStatus(status)
            
            if status.valveState != lastValveState {
                configureView()
            }
        }
    }
    
    // MARK: - Animations related methods
    @objc fileprivate func configureView() {
        valveButton.isEnabled = device.isConnected && device.valveState != .inTransition
        view.layer.removeAllAnimations()
        view.alpha = device.isConnected ? 1 : 0.4
        
        startAnimations()
    }
    
    @objc fileprivate func startAnimations() {
        stopAnimations()
        
        let newValveState = device.valveState
        if lastValveState != newValveState {
            lastValveState = newValveState
            animateValve(to: newValveState)
        }
        animateFlow(to: newValveState)
    }
    
    @objc fileprivate func stopAnimations() {
        for subview in view.subviews {
            subview.layer.removeAllAnimations()
        }
        restartFlowPosition()
    }
    
    fileprivate func registerToNotificationsForCurrentDevice() {
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startAnimations),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopAnimations),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onUpdate(_:)),
            name: device.statusUpdateNotificationName,
            object: nil)
        
        //Notification for when the valve open/close is triggered from the device image
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(valveAction),
            name: DeviceDataCardViewController.kNotificationChangeValveState,
            object: nil)
    }
    
    fileprivate func restartFlowPosition() {
        waterFlowOnImageView.frame.origin = CGPoint(
            x: view.frame.width - waterFlowOnImageView.frame.width,
            y: waterFlowOnImageView.frame.origin.y
        )
    }
    
    fileprivate func animateValve(to: ValveState) {
        UIView.animate(withDuration: 0.3) {
            switch to {
            case .open, .inTransition:
                self.valveStatusLabel.text = "valve_on".localized
            case .closed:
                self.valveStatusLabel.text = "valve_off".localized
            case .testRunning:
                self.valveStatusLabel.text = "end_test".localized
            }
            
            self.valveKnotOnImageView.alpha = to == .closed || to == .testRunning ? 0 : (to == .inTransition ? 0.4 : 1)
            self.valveKnotOffImageView.alpha = to == .closed || to == .testRunning ? 1 : 0
            
            let endTransform = (to == .open || to == .inTransition) ? CGAffineTransform.identity.rotated(by: .pi / -2) : CGAffineTransform.identity
            self.valveKnotOnImageView.transform = endTransform
        }
    }
    
    fileprivate func animateFlow(to: ValveState) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.waterFlowOnImageView.alpha = to == .closed || to == .testRunning ? 0 : (to == .inTransition ? 0.4 : 1)
                self.waterFlowOffImageView.alpha = to == .closed || to == .testRunning ? 1 : 0
            },
            completion: { completed in
                if completed {
                    UIView.animate(
                        withDuration: 5,
                        delay: 0,
                        options: [.repeat, .curveLinear],
                        animations: {
                            self.waterFlowOnImageView.frame.origin = CGPoint(x: 0, y: self.waterFlowOnImageView.frame.origin.y)
                        },
                        completion: { completed in
                            if completed {
                                self.waterFlowOnImageView.frame.origin = CGPoint(
                                    x: self.view.frame.width - self.waterFlowOnImageView.frame.width,
                                    y: self.waterFlowOnImageView.frame.origin.y
                                )
                            }
                        }
                    )
                }
            }
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startAnimations()
    }
    
    // MARK: - Demo mode
    public func changeValve(to: ValveState) {
        animateValve(to: to)
        animateFlow(to: to)
    }
}
