//
//  LoadingViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 6/9/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

import UIKit
import Embrace

internal class LoadingViewController: FloBaseViewController {
    
    fileprivate static let kRetryTime = 5.0
    fileprivate static let kRetryMaxAttempts = 3
    fileprivate static let kDelayedLaunchTime = 1.5
    
    @IBOutlet fileprivate weak var txtErrorMessage: UILabel!
    
    fileprivate var retryTimer: Timer?
    fileprivate var retryCount = 0
    fileprivate var delayedLaunchTimer: Timer?
    fileprivate var hasAllDataToProceed = false
    fileprivate var delayedLaunchTimerHasFinished = false
    fileprivate var controllerToPush: UIViewController?
    
    override func shouldHideNavBar() -> Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AppVersionHelper.checkIfNeedsUpdate { (needsUpdate) in
            if needsUpdate {
                AppVersionHelper.showNeedsUpdatePopup()
            } else {
                self.prepareAppForLaunch()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.invalidateRetryTimer()
        self.invalidateDelayedLaunchTimer()
    }
    
    fileprivate func prepareAppForLaunch() {
        self.invalidateDelayedLaunchTimer()
        self.delayedLaunchTimerHasFinished = false
        self.delayedLaunchTimer = Timer.scheduledTimer(
            timeInterval: LoadingViewController.kDelayedLaunchTime,
            target: self,
            selector: #selector(self.delayedLunchTimerFired(timer:)),
            userInfo: nil,
            repeats: false)
        
        if !checkConnection() {
            return
        }
        
        if !checkUserHasActiveSession() {
            return
        }
        
        getUserInfo()
    }
    
    fileprivate func checkConnection() -> Bool {
        if !FloGlobalServices.instance.isConnected() {
            LoggerHelper.log("No Internet Detected", level: .error)
            
            let optionRetry = AlertPopupOption(title: "retry".localized, type: .normal) { self.retryFromScratch() }
            self.showPopup(title: "error_popup_title".localized + " 008",
                           description: "no_internet_connection_detected".localized,
                           options: [optionRetry])
            return false
        }
        return true
    }
    
    fileprivate func checkUserHasActiveSession() -> Bool {
        if let auth = UserSessionManager.shared.authorization {
            TrackingManager.shared.identify(auth.userId)
            AWSPinpointManager.shared.loginUser(withId: auth.userId)
            AWSPinpointManager.shared.logEvent("autologin", withParams: ["user_id": auth.userId])
            return true
        } else {
            self.goToLogin()
            return false
        }
    }
    
    fileprivate func getUserInfo() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let mainNavigation = storyboard.instantiateViewController(
            withIdentifier: TabBarController.storyboardId) as? TabBarController {
            if let navController = mainNavigation.viewControllers?.first as? UINavigationController {
                if let homeController = navController.viewControllers.first as? DashboardViewController {
                    self.retryInfoFetch(homeController, controllerToPushOnSuccess: mainNavigation)
                }
            }
        }
    }
    
    fileprivate func retryFromScratch() {
        self.txtErrorMessage.isHidden = true
        retryCount = 0
        prepareAppForLaunch()
    }
    
    fileprivate func retryInfoFetch(_ controller: DashboardViewController, controllerToPushOnSuccess: UIViewController) {
        if retryCount >= LoadingViewController.kRetryMaxAttempts {
            LoggerHelper.log("Reached Max attempts to fetch info on Splash", level: .error)
            
            let optionRetry = AlertPopupOption(title: "retry".localized, type: .normal) { self.retryFromScratch() }
            let optionOk = AlertPopupOption(title: "cancel".localized, type: .cancel) { self.goToLogin() }
            showPopup(
                title: "error_popup_title".localized + " 009",
                description: "cannot_communicate_with_flo_servers".localized,
                options: [optionRetry, optionOk]
            )
            
            txtErrorMessage.isHidden = true
            retryCount = 0
            return
        }
        
        retryCount += 1
        LoggerHelper.log("Attempt \(retryCount) to fetch info on Splash", level: .debug)
        invalidateRetryTimer()
        
        UserSessionManager.shared.getUser { (error, _) in
            if let e = error {
                self.retryTimer = Timer.scheduledTimer(
                    timeInterval: LoadingViewController.kRetryTime,
                    target: self,
                    selector: #selector(self.retryTimerDidFire(timer:)),
                    userInfo: ["controller": controller, "success_controller": controllerToPushOnSuccess],
                    repeats: false
                )
                
                self.txtErrorMessage.isHidden = false
                if let message = e.originalServerMessage {
                    self.txtErrorMessage.text = (self.txtErrorMessage.text ?? "") + " (Error: \(message))"
                }
            } else {
                self.txtErrorMessage.isHidden = true
                self.retryCount = 0
                
                LocationsManager.shared.getAll { success in
                    if success {
                        self.controllerToPush = controllerToPushOnSuccess
                        self.hasAllDataToProceed = true
                        if self.delayedLaunchTimerHasFinished {
                            self.pushPendingController()
                        }
                    } else {
                        let optionRetry = AlertPopupOption(title: "retry".localized, type: .normal) {
                            self.retryFromScratch()
                        }
                        self.showPopup(description: "something_went_wrong_please_retry".localized, options: [optionRetry])
                    }
                }
            }
        }
    }
    
    @objc fileprivate func retryTimerDidFire(timer: Timer) {
        self.txtErrorMessage.isHidden = false
        if let userInfo = timer.userInfo as? [String: Any],
            let controller = userInfo["controller"] as? DashboardViewController,
            let controllerToPush = userInfo["success_controller"] as? UIViewController {
                self.retryInfoFetch(controller, controllerToPushOnSuccess: controllerToPush)
        }
    }
    
    fileprivate func invalidateRetryTimer() {
        if let timer = self.retryTimer, timer.isValid {
            timer.invalidate()
        }
        self.retryTimer = nil
    }
    
    @objc fileprivate func delayedLunchTimerFired(timer: Timer) {
        self.invalidateDelayedLaunchTimer()
        if hasAllDataToProceed {
            self.pushPendingController()
        }
    }
    
    fileprivate func invalidateDelayedLaunchTimer() {
        self.delayedLaunchTimerHasFinished = true
        if let timer = self.delayedLaunchTimer, timer.isValid {
            timer.invalidate()
        }
        self.delayedLaunchTimer = nil
    }
    
    fileprivate func goToLogin() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        
        if let controller = storyboard.instantiateViewController(
            withIdentifier: LoginViewController.storyboardId) as? LoginViewController {
            
            let navController = UINavigationController(rootViewController: controller)
            self.controllerToPush = navController
            self.hasAllDataToProceed = true
            if delayedLaunchTimerHasFinished {
                self.pushPendingController()
            }
        }
    }
    
    fileprivate func pushPendingController() {
        if controllerToPush != nil {
            //End startup moment for Embrace
            Embrace.sharedInstance()?.endAppStartup()
            
            UIApplication.shared.switchRootViewController(controllerToPush!, animated: true)
        }
    }
    
}
