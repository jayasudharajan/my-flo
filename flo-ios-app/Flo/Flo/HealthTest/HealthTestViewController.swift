//
//  HealthTestViewController.swift
//  Flo
//
//  Created by Josefina Perez on 18/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

protocol HealthTestDelegate: class {
    func cancelHealthTest()
}

import UIKit

internal class HealthTestViewController: FloBaseViewController, HealthTestDelegate {
    
    @IBOutlet fileprivate weak var valveView: UIView!
    @IBOutlet fileprivate weak var loadingView: UIView!
    @IBOutlet fileprivate weak var runningView: UIView!
    @IBOutlet fileprivate weak var timeRemainingView: UIView!
    @IBOutlet fileprivate weak var lblTimeRemaining: UILabel!
    @IBOutlet fileprivate weak var lblCompletedPercentage: UILabel!
    @IBOutlet fileprivate weak var progressAnimationView: CircularProgressView!
    @IBOutlet fileprivate weak var lightBlueView: UIView!
    
    fileprivate var valveController = ValveCardViewController.getInstance() as? ValveCardViewController ?? ValveCardViewController()
    fileprivate var remainingSeconds = 300 // 5min
    fileprivate var completedPercentage  = 0
    fileprivate var currentStatus: HealthTestStatus?
    
    public var device: DeviceModel!
    
    fileprivate var progressTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(
            andTitle: "health_test".localized(),
            tint: StyleHelper.colors.white,
            titleColor: StyleHelper.colors.white
        )
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        valveController.updateWith(deviceInfo: device)
        valveController.delegate = self
        
        addContentController(valveController, toView: valveView)
        
        currentStatus = device.healthTestStatus
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onUpdate(_:)),
            name: device.statusUpdateNotificationName,
            object: nil
        )
        
        LocationsManager.shared.startTrackingDevice(device)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if device.healthTestStatus == .running && device.valveState == .testRunning {
            calculateProgress()
            configureAsTestRunning(animated: false)
        } else {
            // Resets health test state in case valve was still opening.
            device.healthTestStatus = .pending
            currentStatus = .pending
            configureAsTestPending()
            
            // Fake flow for demo mode
            if FloApiRequest.demoModeEnabled() {
                Timer.scheduledTimer(
                    timeInterval: 5,
                    target: self,
                    selector: #selector(self.configureAsTestRunning),
                    userInfo: nil,
                    repeats: false
                )
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configure initial state (pending)
    fileprivate func configureAsTestPending() {
        if FloApiRequest.demoModeEnabled() {
            device.healthTestStatus = .pending
            device.valveState = .open
        }
        
        loadingView.isHidden = false
        runningView.isHidden = true
        timeRemainingView.isHidden = true
        
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        actInd.frame = CGRect(
            x: (loadingView.frame.width / 2) - 20,
            y: (loadingView.frame.height / 2) - 20,
            width: 40.0,
            height: 40.0
        )
        actInd.hidesWhenStopped = true
        actInd.color = StyleHelper.colors.green
        loadingView.addSubview(actInd)
        actInd.startAnimating()
    }
    
    // MARK: - Configure state (running)
    @objc fileprivate func configureAsTestRunning(animated: Bool = true) {
        addRightNavBarItem(
            title: "cancel".localized,
            tint: StyleHelper.colors.transparency50,
            onTap: #selector(cancelHealthTest)
        )

        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.loadingView.alpha = 0
            self.timeRemainingView.alpha = 1
            self.runningView.alpha = 1
        }, completion: { _ in
            self.loadingView.isHidden = true
            self.runningView.isHidden = false
            self.timeRemainingView.isHidden = false

            self.updateProgress()
            
            if FloApiRequest.demoModeEnabled() {
                self.device.healthTestStatus = .running
                self.device.valveState = .closed
                self.valveController.updateWith(deviceInfo: self.device)
                self.valveController.changeValve(to: .testRunning)
            }

            // 1% every 3 seconds
            self.progressTimer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.updateProgress),
                userInfo: nil,
                repeats: true
            )
        })
    }
    
    // MARK: - Calculate the current status of an already running test
    fileprivate func calculateProgress() {
        showLoadingSpinner("loading".localized)
        HealthTestHelper.getHealthTestStatus(device: device, whenFinished: { (error, results) in
            self.hideLoadingSpinner()
            if let e = error {
                self.showPopup(error: e)
            } else if let results = results {
                let totalDuration = 300
                self.remainingSeconds = totalDuration - results.testDuration
                self.completedPercentage = (results.testDuration * 100) / totalDuration
            }
        })
    }
    
    // MARK: - Call this function to update the UI with the test progress
    @objc fileprivate func updateProgress() {
        lblTimeRemaining.text = "\(remainingSeconds / 60):\(String(format: "%02d", (remainingSeconds % 60)))"
        lblCompletedPercentage.text = "\(completedPercentage)%"
        
        progressAnimationView.drawProgress(endPercent: completedPercentage, lineHeight: lightBlueView.frame.width / 2 + 5)
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            completedPercentage = remainingSeconds % 3 == 0 ? completedPercentage + 1 : completedPercentage
        }
        
        if remainingSeconds == 0 {
            progressTimer?.invalidate()
            progressTimer = nil
            showResults()
        }
        
        // Fake flow for demo mode
        if FloApiRequest.demoModeEnabled() && (remainingSeconds != 0 && remainingSeconds % 10 == 0) {
            device.healthTestStatus = .completed
            device.valveState = .open
            speedUpAnimation()
        }
    }
    
    // MARK: - Cancel health test
    @objc public func cancelHealthTest() {
        showPopup(
            title: "cancel_health_test".localized,
            description: "are_you_sure_you_want_to_cancel_health_test_q".localized,
            options: [
                AlertPopupOption(title: "yes".localized, type: .normal, action: {
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    
                    guard !FloApiRequest.demoModeEnabled() else {
                        self.device.healthTestStatus = .canceled
                        self.showResults(cancelledInDemoMode: true)
                        return
                    }
                    
                    self.showLoadingSpinner("loading".localized)
                    HealthTestHelper.cancelHealthTest(device: self.device, whenFinished: {(error) in
                        if let e = error {
                            self.hideLoadingSpinner()
                            LoggerHelper.log(e.message, level: .error)
                            self.showPopup(error: e)
                        }
                    })
                }),
                AlertPopupOption(title: "no".localized, type: .cancel, action: nil)
            ]
        )
    }
    
    fileprivate func showResults(cancelledInDemoMode: Bool = false) {
        guard let resultsController = storyboard?.instantiateViewController(withIdentifier: HealthTestResultsViewController.storyboardId) as? HealthTestResultsViewController else {
            return
        }
        
        if FloApiRequest.demoModeEnabled() {
            resultsController.testCancelledInDemoMode = cancelledInDemoMode
        }
        
        resultsController.device = device
        navigationController?.pushViewController(resultsController, animated: true)
    }
    
    // MARK: - Device status
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress, let healthTestStatus = status.healthTestStatus {
            device.setStatus(status)
            
            switch healthTestStatus {
            case .pending:
                currentStatus = healthTestStatus
            case .running:
                if currentStatus == .pending && status.valveState == .testRunning {
                    currentStatus = healthTestStatus
                    configureAsTestRunning()
                }
            case .completed:
                if currentStatus == .running {
                    NotificationCenter.default.removeObserver(self)
                    currentStatus = healthTestStatus
                    speedUpAnimation()
                }
            case .canceled:
                if currentStatus == .running {
                    NotificationCenter.default.removeObserver(self)
                    currentStatus = healthTestStatus
                    showResults()
                }
            case .timeout:
                NotificationCenter.default.removeObserver(self)
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Animations
    fileprivate func speedUpAnimation() {
        let timeInterval: Double = Double(2 / (100 - completedPercentage))
        progressTimer?.invalidate()
        progressTimer = nil
        
        progressTimer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(self.updateProgress),
            userInfo: nil,
            repeats: true
        )
    }
}
