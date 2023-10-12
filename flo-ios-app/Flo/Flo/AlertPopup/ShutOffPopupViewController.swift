//
//  ShutOffPopupViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 15/11/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class ShutOffPopupViewController: FloBaseViewController {
    
    fileprivate static let semaphore = DispatchSemaphore(value: 1)
    fileprivate static var onTop = false
    fileprivate var device: DeviceModel!
    fileprivate var refreshTimer: Timer?

    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var locationLabel: UILabel!
    @IBOutlet fileprivate weak var deviceLabel: UILabel!
    @IBOutlet fileprivate weak var timerContainerView: UIView!
    @IBOutlet fileprivate weak var timerView: UIView!
    @IBOutlet fileprivate weak var timerLabel: UILabel!
    
    @IBAction fileprivate func shutOffAction() {
        showLoadingSpinner("loading".localized)
        DevicesHelper.setValveState(.closed, for: device.id) { (error, _) in
            if let e = error {
                self.hideLoadingSpinner()
                self.showPopup(error: e)
            }
        }
    }
    
    @IBAction fileprivate func keepRunningAction() {
        showLoadingSpinner("loading".localized)
        DevicesHelper.setKeepWaterRunning(for: device.id) { (error) in
            if let e = error {
                self.hideLoadingSpinner()
                self.showPopup(error: e)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = StyleHelper.colors.black.cgColor
        containerView.layer.shadowOffset = .zero
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 8
        
        timerContainerView.layer.cornerRadius = 10
        timerView.layer.cornerRadius = 10
        
        // Background blur effect
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = view.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
        
        locationLabel.text = LocationsManager.shared.getOneByDeviceLocally(device.id)?.nickname
        deviceLabel.text = device.nickname
        
        tick()
        refreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ShutOffPopupViewController.onTop = false
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Timer function
    @objc fileprivate func tick() {
        if let shutOffDate = device.willShutOffAt, shutOffDate > Date() {
            let components = Calendar.current.dateComponents([.minute, .second], from: Date(), to: shutOffDate)
            if let minutes = components.minute, let seconds = components.second {
                let secondsString = (seconds < 10 ? "0" : "") + "\(seconds)"
                timerLabel.text = "\(minutes):" + secondsString
            }
        } else {
            hideLoadingSpinner()
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Instantiation
    public class func instantiate(for device: DeviceModel) {
        semaphore.wait()
        if !onTop {
            onTop = true
            semaphore.signal()
            
            let storyboard = UIStoryboard(name: "Common", bundle: nil)
            
            guard
                let rootViewController = UIApplication.shared.keyWindow?.rootViewController,
                let tabBarController = rootViewController as? TabBarController,
                let tabController = tabBarController.selectedViewController,
                let navController = tabController as? UINavigationController,
                let shutOffVC = storyboard.instantiateViewController(withIdentifier: ShutOffPopupViewController.storyboardId) as? ShutOffPopupViewController
            else { return }
            
            shutOffVC.device = device
            navController.present(shutOffVC, animated: true, completion: nil)
        } else {
            semaphore.signal()
        }
    }
}
